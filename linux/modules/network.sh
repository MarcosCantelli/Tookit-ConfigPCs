#!/usr/bin/env bash
# network.sh - configuração de IP fixo.
#
# Ubuntu Server usa netplan por padrão -> aplicamos com "netplan try", que reverte
# SOZINHO se a conexão cair (proteção contra travar o acesso via SSH).
#
# Oracle Linux usa NetworkManager (nmcli) por padrão -> esse caminho NÃO tem revert
# automático. Se só tiver acesso via SSH, tenha um console de emergência (iLO/iDRAC/
# console do provedor de nuvem) antes de aplicar.

detect_default_interface() {
    ip route show default 2>/dev/null | awk '/default/ {print $5; exit}'
}

configure_static_ip_netplan() {
    local iface="$1" ip_cidr="$2" gateway="$3" dns="$4"

    for f in /etc/netplan/*.yaml; do
        [ -e "$f" ] || continue
        if grep -q "$iface" "$f" 2>/dev/null; then
            mv "$f" "${f}.bak.$(date +%s)"
            log "Netplan existente '$f' já configurava '$iface' - renomeado para .bak (desativado) pra não brigar com a config nova." "WARN"
        fi
    done

    local netplan_file="/etc/netplan/01-toolkit-static.yaml"
    cat > "$netplan_file" <<EOF
network:
  version: 2
  ethernets:
    $iface:
      dhcp4: no
      addresses: [$ip_cidr]
      routes:
        - to: default
          via: $gateway
      nameservers:
        addresses: [$dns]
EOF
    chmod 600 "$netplan_file"

    log "Aplicando com 'netplan try' (30s - reverte sozinho se a conexão cair; pressione Enter pra confirmar se continuar acessível)..."
    if netplan try --timeout 30; then
        log "IP fixo aplicado e confirmado via netplan em $iface." "OK"
    else
        log "netplan try falhou ou expirou - a configuração provavelmente foi revertida sozinha. Confira com 'netplan status'." "ERROR"
    fi
}

configure_static_ip_nmcli() {
    local iface="$1" ip_cidr="$2" gateway="$3" dns="$4"
    local con_name
    con_name="$(nmcli -t -f NAME,DEVICE con show --active | awk -F: -v d="$iface" '$2==d {print $1; exit}')"
    [ -z "$con_name" ] && con_name="$iface"

    log "Configurando IP fixo via nmcli na conexão '$con_name' ($iface)..."
    nmcli con mod "$con_name" ipv4.addresses "$ip_cidr" ipv4.gateway "$gateway" ipv4.dns "$dns" ipv4.method manual
    nmcli con up "$con_name"
    log "IP fixo aplicado via NetworkManager em $iface." "OK"
}

invoke_static_ip_config() {
    local iface
    iface="$(detect_default_interface)"
    if [ -z "$iface" ]; then
        read -rp "Não detectei a interface de rede automaticamente. Informe o nome (ex: eth0, ens18): " iface
    else
        log "Interface de rede detectada: $iface"
    fi

    read -rp "IP fixo com máscara CIDR (ex: 192.168.1.50/24): " ip_cidr
    read -rp "Gateway (ex: 192.168.1.1): " gateway
    read -rp "DNS (ex: 8.8.8.8, separe por vírgula se mais de um): " dns

    echo ""
    echo "Confirme os dados:"
    echo "  Interface: $iface"
    echo "  IP:        $ip_cidr"
    echo "  Gateway:   $gateway"
    echo "  DNS:       $dns"
    echo ""
    echo "ATENÇÃO: se você estiver conectado via SSH, uma configuração errada pode"
    echo "derrubar o acesso remoto à máquina. Confira os dados com cuidado."
    read -rp "Aplicar essa configuração agora? (s/N) " confirm
    if [ "$confirm" != "s" ] && [ "$confirm" != "S" ]; then
        log "Configuração de IP cancelada pelo usuário." "WARN"
        return
    fi

    if command -v netplan >/dev/null 2>&1; then
        configure_static_ip_netplan "$iface" "$ip_cidr" "$gateway" "$dns"
    elif command -v nmcli >/dev/null 2>&1; then
        echo "ATENÇÃO: nmcli não reverte sozinho se a conexão cair. Se só tiver acesso via SSH, tenha um console de emergência (iLO/iDRAC/console do provedor) de reserva."
        configure_static_ip_nmcli "$iface" "$ip_cidr" "$gateway" "$dns"
    else
        log "Nem netplan nem nmcli disponíveis; não sei configurar IP fixo nessa distro." "ERROR"
    fi
}
