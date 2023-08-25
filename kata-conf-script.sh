cat > update-registries.sh << 'EOF'
#!/bin/bash

# Vérifier si l'utilisateur est root
if [ "$(id -u)" -ne 0 ]; then
  echo "Ce script doit être exécuté en tant que root."
  exit 1
fi

# Créer le répertoire s'il n'existe pas
mkdir -p /etc/containers/registries.conf.d

# Ajouter 'docker.io' dans '01-unqualified'
echo 'unqualified-search-registries = ["docker.io"]' > /etc/containers/registries.conf.d/01-unqualified

# Prompt pour choisir entre CRI-O et containerd
echo "Veuillez choisir le runtime de conteneur à configurer:"
echo "1) CRI-O"
echo "2) containerd"
read -p "Choix: " choice

# Configurer le fichier de service systemd de kubelet en fonction du choix
case $choice in
  1)
    mkdir -p /etc/systemd/system/kubelet.service.d
    echo -e "[Service]\nEnvironment=\"KUBELET_EXTRA_ARGS=--container-runtime=remote --runtime-request-timeout=15m --container-runtime-endpoint=unix:///var/run/crio/crio.sock\"" > /etc/systemd/system/kubelet.service.d/0-crio.conf
    ;;
  2)
    mkdir -p /etc/systemd/system/kubelet.service.d
    echo -e "[Service]\nEnvironment=\"KUBELET_EXTRA_ARGS=--container-runtime=remote --runtime-request-timeout=15m --container-runtime-endpoint=unix:///run/containerd/containerd.sock\"" > /etc/systemd/system/kubelet.service.d/0-cri-containerd.conf
    ;;
  *)
    echo "Choix non valide."
    exit 1
    ;;
esac

# Recharger les configurations du système et redémarrer les services
systemctl daemon-reload
systemctl restart crio cri-o kubelet containerd

echo "Configuration modifiée et services redémarrés."
EOF

# Rendre le script exécutable
chmod +x update-registries.sh

# Exécuter le script
sudo ./update-registries.sh
