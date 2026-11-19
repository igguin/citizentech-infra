# CitizenTech — Infraestrutura Linux

## GS — Operating Systems (Linux)

Projeto acadêmico de infraestrutura Linux automatizada para hospedar a aplicação web SoloCerto, desenvolvida no contexto do CitizenTech.

## Integrantes

- Victor Mattenhauer Lopes Capp — RM 555753
- Jose Antonio Kretzer Rodriguez — RM 555523
- Igor Brunelli Ralo — RM 555035

## 1. Objetivo

Desenvolver uma infraestrutura Linux funcional, automatizada e monitorada, capaz de hospedar a aplicação SoloCerto.

A solução utiliza Shell Script (Bash), systemd, monitoramento de recursos, logs de auditoria e mecanismos de recuperação de falhas.

## 2. Tecnologias utilizadas

- Debian GNU/Linux 13
- Oracle VirtualBox
- Shell Script (Bash)
- systemd
- Nginx
- Node.js 24
- npm
- React Native / Expo / TypeScript
- Git e GitHub
- OpenSSH

## 3. Arquitetura

O ambiente utiliza uma máquina virtual Debian 13 executada no VirtualBox.

O código-fonte da aplicação está armazenado na pasta `aplicacao/`.

O script de provisionamento instala as dependências, compila a versão web do SoloCerto e publica os arquivos no Nginx.

O Nginx disponibiliza a aplicação pela porta 80.

Um serviço systemd separado executa periodicamente o monitoramento dos recursos computacionais.

## 4. Estrutura do repositório

- `aplicacao/` — código-fonte do SoloCerto.
- `scripts/provisionar.sh` — provisionamento principal.
- `scripts/publicar-solocerto.sh` — publicação no Nginx.
- `scripts/monitorar.sh` — monitoramento de CPU, RAM e disco.
- `scripts/instalar-monitoramento.sh` — instalação do serviço de monitoramento.
- `services/citizentech-monitor.service` — configuração systemd.
- `evidencias/` — resultados dos testes e registros técnicos.

## 5. Pré-requisitos

- Máquina virtual com Debian 13.
- Conexão com a internet.
- Usuário `citizenadmin` com permissões sudo.
- Git instalado.
- Acesso aos repositórios Debian e NodeSource.

O ambiente testado utiliza 2 CPUs, 2 GB de RAM e disco virtual de 30 GB.

## 6. Instalação e provisionamento

No Debian, instale o Git, caso necessário:

```bash
sudo apt update
sudo apt install -y git
```

Clone o repositório:

```bash
cd /home/citizenadmin
git clone https://github.com/igguin/citizentech-infra.git
cd citizentech-infra
```

Execute o provisionamento:

```bash
sudo bash scripts/provisionar.sh
```

O script realiza:

1. Configuração do hostname.
2. Verificação de endereçamento IP e DNS.
3. Instalação das dependências necessárias.
4. Instalação ou verificação do Node.js 24.
5. Instalação das dependências npm.
6. Compilação da aplicação web.
7. Configuração e ativação do Nginx.
8. Configuração do monitoramento systemd.
9. Ativação do serviço SSH.
10. Validações automáticas dos serviços.

O provisionamento registra suas atividades em:

`/var/log/citizentech/provisionamento.log`

## 7. Configuração de rede

Hostname: `citizentech-server`

A máquina virtual utiliza adaptador NAT do VirtualBox, com endereçamento fornecido por DHCP.

No ambiente utilizado nos testes, o endereço interno foi `10.0.2.15`.

A conexão SSH foi disponibilizada através do redirecionamento:

- IP do hospedeiro: `127.0.0.1`
- Porta do hospedeiro: `2222`
- IP do convidado: `10.0.2.15`
- Porta do convidado: `22`

O script principal verifica os endereços de rede, a rota padrão e a resolução DNS.

A configuração NAT e o redirecionamento de portas são realizados no VirtualBox.

## 8. Acesso à aplicação

No Debian, o Nginx disponibiliza a aplicação em:

`http://127.0.0.1/`

Para acessar pelo navegador do Windows usando o túnel SSH, execute no PowerShell:

```powershell
ssh -N -L 18080:127.0.0.1:80 -p 2222 citizenadmin@127.0.0.1
```

Depois acesse:

`http://localhost:18080`

Mantenha o túnel SSH aberto durante o acesso.

## 9. Monitoramento

O script `scripts/monitorar.sh` verifica:

- Utilização de CPU.
- Consumo de memória RAM.
- Utilização de disco.

Limites padrão:

- CPU: 80%.
- RAM: 85%.
- Disco: 90%.

A execução periódica é gerenciada pelo serviço:

`citizentech-monitor.service`

Comandos de administração:

```bash
sudo systemctl start citizentech-monitor.service
sudo systemctl stop citizentech-monitor.service
sudo systemctl restart citizentech-monitor.service
systemctl status citizentech-monitor.service
```

O serviço está configurado para reiniciar automaticamente após falhas inesperadas.

## 10. Logs e auditoria

Os registros estão em:

- `/var/log/citizentech/monitoramento.log`
- `/var/log/citizentech/instalacao.log`
- `/var/log/citizentech/provisionamento.log`
- `/var/log/citizentech/publicacao.log`

Para consultar os registros do systemd:

```bash
sudo journalctl -u citizentech-monitor.service -n 30 --no-pager
```

Para consultar o monitoramento:

```bash
sudo tail -n 20 /var/log/citizentech/monitoramento.log
```

## 11. Testes realizados

### Monitoramento de recursos

Foram verificadas as medições de CPU, memória RAM e disco.

### Teste de alertas

Foram utilizados limites artificiais negativos para testar a lógica de emissão de alertas, sem provocar sobrecarga real.

Evidência: `evidencias/teste-alertas.txt`

### Falha e recuperação automática

O processo principal do monitoramento foi interrompido com SIGKILL.

O systemd detectou a falha e reiniciou o serviço automaticamente após aproximadamente 5 segundos.

Evidência: `evidencias/recuperacao-monitoramento.txt`

### Falha controlada no provisionamento

O script foi executado em um diretório temporário sem o código da aplicação.

O provisionamento identificou a ausência dos arquivos e encerrou com código de erro 1.

Evidência: `evidencias/falha-controlada.txt`

### Reinicialização do Debian

Após reiniciar a máquina virtual, foram verificados:

- Nginx ativo e habilitado.
- Monitoramento ativo e habilitado.
- SSH ativo.
- Resposta HTTP 200 da aplicação web.

Evidência: `evidencias/teste-reinicializacao.txt`

### Validação geral

Evidência: `evidencias/validacao-infraestrutura.txt`

## 12. Considerações finais

A infraestrutura implementada permite hospedar a versão web do SoloCerto em um servidor Debian, automatizar a instalação das dependências e administrar os serviços utilizados.

Os testes demonstraram o funcionamento do monitoramento, da geração de logs, dos alertas e da recuperação automática do serviço após falha.

A solução utiliza ferramentas nativas do Linux e scripts Bash para facilitar a administração e a reprodução do ambiente.
