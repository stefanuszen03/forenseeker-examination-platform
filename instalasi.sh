#!/bin/bash

# Banner ASCII
echo "
__________                        ________         ______              
___  ____/__________________________  ___/____________  /______________
__  /_   _  __ \_  ___/  _ \_  __ \____ \_  _ \  _ \_  //_/  _ \_  ___/
_  __/   / /_/ /  /   /  __/  / / /___/ //  __/  __/  ,<  /  __/  /    
/_/      \____//_/    \___//_/ /_//____/ \___/\___//_/|_| \___//_/     
                                                                       
Platform Eksaminasi Forensik Digital Otomatis
by Stefanus Zen
"

# Fungsi untuk mengecek dan menginstall package
check_and_install() {
    if ! command -v $1 &> /dev/null; then
        echo "Menginstall $1..."
        sudo apt-get install -y $1
    else
        echo "$1 sudah terinstall"
    fi
}

# Fungsi verifikasi instalasi
verify_installation() {
    local tools=(
        "vol3"
        "rekall"
        "tshark"
        "bruteshark-cli"
        "aletheia"
        "zsteg"
        "exiftool"
        "binwalk"
        "foremost"
        "bulk_extractor"
        "strings"
        "xxd"
        "convert"  # ImageMagick
        "ruby"
        "python3"
        "mono-runtime"
        "sha256sum"
        "md5sum"
        "sha1sum"
        "mmls"
        "fls"
    )
    
    for tool in "${tools[@]}"; do
        if ! command -v $tool &> /dev/null; then
            echo "Error: $tool tidak terinstall dengan benar"
            return 1
        fi
    done
    echo "✓ Semua tools terinstall dengan benar"
}

# Validasi nama file
if [[ ! "$0" =~ "instalasi.sh" ]]; then
    echo "Perintah yang digunakan salah"
    echo "Gunakan: ./instalasi.sh"
    exit 1
fi

# Update repository
echo "Memperbarui repository..."
sudo apt-get update

# Install dependencies dasar
dependencies=(
    "curl"
    "python3"
    "python3-pip"
    "build-essential"
    "git"
    "libpcap-dev"
    "cmake"
    "automake"
    "autoconf"
    "libtool"
    "ruby"
    "ruby-dev"
    "mono-complete"
    "coreutils"
)

for dep in "${dependencies[@]}"; do
    check_and_install $dep
done

# Buat direktori tools
TOOLS_DIR=~/tools
if [ ! -d "$TOOLS_DIR" ]; then
    mkdir -p $TOOLS_DIR
fi
cd $TOOLS_DIR

# Perbaikan instalasi Volatility3
echo "Menginstall Volatility..."
cd $TOOLS_DIR

# Coba instalasi dengan pip terlebih dahulu
echo "Mencoba instalasi Volatility menggunakan pip..."
python3 -m pip install volatility3

# Jika instalasi pip gagal, coba dengan git clone
if ! command -v vol3 &> /dev/null; then
    echo "Instalasi pip gagal, mencoba dengan git clone..."
    
    # Hapus folder volatility3 jika sudah ada
    rm -rf volatility3
    
    # Clone repository
    if git clone https://github.com/volatilityfoundation/volatility3.git; then
        cd volatility3
        # Install dependencies
        python3 -m pip install -r requirements.txt || true
        # Install Volatility3
        python3 setup.py install || true
        # Buat symlink
        which vol && sudo ln -sf "$(which vol)" /usr/local/bin/vol3
        cd ..
    fi
fi

# Verifikasi instalasi Volatility
if command -v vol3 &> /dev/null || command -v vol &> /dev/null; then
    echo "✓ Instalasi Volatility selesai"
else
    echo "! Warning: Gagal menginstall Volatility, melanjutkan instalasi tools lainnya..."
fi

# Lanjutkan dengan instalasi tool lainnya
echo "Menginstall The Sleuth Kit..."
check_and_install sleuthkit
echo "✓ Instalasi The Sleuth Kit selesai"

tools=(
    "foremost"
    "bulk-extractor"
    "binwalk"
    "xxd"
    "imagemagick"
    "exiftool"
    "tshark"
)

for tool in "${tools[@]}"; do
    check_and_install $tool
    echo "✓ Instalasi $tool selesai"
done

echo "Menginstall Rekall..."
pip3 install rekall
echo "✓ Instalasi Rekall selesai"

echo "Menginstall NetworkMiner..."
wget https://www.netresec.com/?download=NetworkMiner -O NetworkMiner.zip
unzip NetworkMiner.zip -d NetworkMiner
rm NetworkMiner.zip
echo "✓ Instalasi NetworkMiner selesai"

echo "Menginstall Aletheia..."
cd $TOOLS_DIR
# Hapus instalasi sebelumnya jika ada
rm -rf aletheia

# Clone repository
git clone https://github.com/daniellerch/aletheia.git
cd aletheia

# Install dependencies yang diperlukan
sudo apt-get install -y python3-pip python3-dev
python3 -m pip install --upgrade pip
python3 -m pip install -r requirements.txt

# Install package tambahan yang diperlukan
sudo apt-get install -y libfftw3-dev libblas-dev liblapack-dev libssl-dev
python3 -m pip install numpy scipy pillow

# Install Aletheia
python3 setup.py build
sudo python3 setup.py install

# Buat symlink untuk memastikan command aletheia tersedia
sudo ln -sf /usr/local/bin/aletheia /usr/bin/aletheia

# Verifikasi instalasi
if command -v aletheia &> /dev/null; then
    echo "✓ Instalasi Aletheia selesai"
else
    echo "Error: Gagal menginstall Aletheia"
    exit 1
fi

cd $TOOLS_DIR

echo "Menginstall zsteg..."
gem install zsteg
echo "✓ Instalasi zsteg selesai"

echo "Menginstall BruteShark..."
wget https://github.com/odedshimon/BruteShark/releases/latest/download/BruteSharkCli
chmod +x BruteSharkCli
mv BruteSharkCli /usr/local/bin/bruteshark-cli
echo "✓ Instalasi BruteShark selesai"

# Verifikasi instalasi
verify_installation

echo "================================================================"
echo "✓ Seluruh tools dan library telah berhasil diunduh dan diperbarui!"
echo "================================================================"