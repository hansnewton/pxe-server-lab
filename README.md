# Servidor PXE

## Pré-requisitos

- [x] Vagrant
- [x] CentOS-7-x86_64-Minimal-2009.iso na raiz deste projeto

Para baixar a imagem use link oficial, exemplo http://ftp.unicamp.br/pub/centos/7/isos/x86_64/CentOS-7-x86_64-Minimal-2009.iso

### Criar o arquivo /etc/vbox/networks.conf
sudo mkdir -p /etc/vbox/

```bash
sudo cat <<EOF > /etc/xinetd.d/tftp /etc/vbox/networks.conf
* 0.0.0.0/0 ::/0
EOF
```


## Etapas

Subir o server:

`vagrant up`

Se tudo correr bem o server vai subir com IP 192.168.200.10 em uma rede propria vboxnetXX

Essa rede deverá ser colocada no cliente em momento correto

## Screenshots

Expected results
![Expected](https://github.com/hansnewton/pxe-server-lab/raw/master/resultado.png)