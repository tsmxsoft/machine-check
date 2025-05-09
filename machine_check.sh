#!/bin/bash
apt install sudo -y
apt install hdparm -y
apt install curl -y
apt install htop -y
apt install vim -y

print_separator() {
  printf -- "========================================\n"
}

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' 

echo -e "${CYAN}Distribuição e versão do Linux instalado:${NC}"
cat /etc/os-release | grep NAME=
cat /etc/os-release | grep VERSION=
print_separator

storage_type=$(cat /sys/block/sda/queue/rotational)
storage_label=""

if [[ $storage_type == "1" ]]; then
  storage_label="${YELLOW}HDD${NC}"
else
  storage_label="${GREEN}SSD${NC}"
fi

echo -e "${CYAN}Tipo de unidade de armazenamento:${NC} $storage_label"
print_separator

echo -e "${CYAN}Unidades de armazenamento:${NC}"
df -h
print_separator

SWAP_SIZE=$(free -g | awk '/Swap:/ {print ($2+0)}')

echo -e "${CYAN}Presença de interface gráfica...${NC}"
if command -v gnome-shell >/dev/null || \
   command -v startkde >/dev/null || \
   command -v xfce4-session >/dev/null || \
   command -v mate-session >/dev/null; then
    echo -e "Ambiente gráfico está instalado"
elif pgrep -x "Xorg" >/dev/null || pgrep -x "wayland" >/dev/null; then
    echo -e "Servidor gráfico em execução"
elif [ -n "$DISPLAY" ]; then
    echo -e "Sessão com interface gráfica detectada"
else
    echo -e "Nenhuma interface gráfica detectada"
fi

print_separator

if [ "$SWAP_SIZE" -lt 16 ]; then
    echo -e "${CYAN}Ajustando memória swap para 16GB...${NC}"
    
    sudo swapoff -a
    sudo fallocate -l 16G /swapfile
    sudo chmod 0600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    
    echo -e "${CYAN}Swap ajustado para 16GB.${NC}"
else
    echo -e "${CYAN}Swap atual é de ${SWAP_SIZE}GB, não é necessário ajuste.${NC}"
fi

print_separator

echo -e "${CYAN}Teste de velocidade de leitura:${NC}"
sudo hdparm -Tt /dev/sda1
print_separator

echo -e "${CYAN}Teste de velocidade de escrita:${NC}"
dd if=/dev/sda1 of=/tmp/testfile bs=1M count=1000 conv=fsync
print_separator

echo -e "${CYAN}Informações de memória RAM:${NC}"
awk '/MemTotal/ {total=$2/1024/1024} /MemFree/ {free=$2/1024/1024} /MemAvailable/ {available=$2/1024/1024} /SwapTotal/ {swap_total=$2/1024/1024} /SwapFree/ {swap_free=$2/1024/1024} END {printf "Total: %.2f GB\nEm uso: %.2f GB\nDisponível: %.2f GB\nSwap Total: %.2f GB\nSwap Free: %.2f GB\n", total, (total - free), available, swap_total, swap_free}' /proc/meminfo
print_separator

echo -e "${CYAN}Informações do CPU:${NC}"
echo -e "${CYAN}Nome do modelo do CPU:${NC} "
cat /proc/cpuinfo | grep "model name" | head -n 1 | awk -F ': ' '{print $2}'
echo -e "${CYAN}Quantidade de Cores do CPU:${NC} "
cat /proc/cpuinfo | grep 'core id' | wc -l 
echo -e "${CYAN}Quantidade de Threads do CPU:${NC} "
grep "siblings" /proc/cpuinfo | uniq | awk -F ': ' '{print $2}'
print_separator

echo -e "${CYAN}Verificando status do Apache:${NC}"
if sudo systemctl is-active apache2 &> /dev/null; then
  echo -e "${GREEN}O serviço Apache está ativo.${NC}"
else
  echo -e "${YELLOW}O serviço Apache não está ativo ou não foi encontrado.${NC}"
fi
print_separator

echo -e "${CYAN}Verificando a existência do diretório /usr/local/sgp:${NC}"
if [ -d "/usr/local/sgp" ]; then
  echo -e "${YELLOW}Já existe um SGP instalado nesta máquina.${NC}"
else
  echo -e "${GREEN}O diretório /usr/local/sgp não foi encontrado.${NC}"
fi
print_separator

echo -e "${CYAN}Verificando se o IP da máquina é público ou privado:${NC}"
public_ip=$(curl -s ifconfig.me)
private_ip=$(hostname -I | awk '{print $1}')

if [[ $private_ip =~ ^10\. ]] || [[ $private_ip =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\. ]] || [[ $private_ip =~ ^192\.168\. ]]; then
  echo -e "${YELLOW}IP privado. Solicitar redirecionamento das portas 80, 443 e 8000.${NC}"
else
  echo -e "${GREEN}IP público.${NC}"
fi
print_separator
