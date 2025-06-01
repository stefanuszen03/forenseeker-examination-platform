#!/bin/bash

# Konfigurasi
source config.sh  # File terpisah untuk menyimpan token Telegram

# Fungsi untuk menampilkan progress bar
show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((width * current / total))
    local remaining=$((width - completed))
    
    printf "\r["
    printf "%${completed}s" | tr " " "█"
    printf "%${remaining}s" | tr " " "░"
    printf "] %d%%" $percentage
}

# Fungsi untuk menampilkan status dengan warna
print_status() {
    local type=$1
    local message=$2
    
    case $type in
        "info")
            echo -e "\e[1;34m[INFO]\e[0m $message"
            ;;
        "success")
            echo -e "\e[1;32m[SUCCESS]\e[0m $message"
            ;;
        "warning")
            echo -e "\e[1;33m[WARNING]\e[0m $message"
            ;;
        "error")
            echo -e "\e[1;31m[ERROR]\e[0m $message"
            ;;
    esac
}

# Fungsi untuk menampilkan header
print_header() {
    clear
    echo -e "\e[1;36m"
    echo "
__________                        ________         ______              
___  ____/__________________________  ___/____________  /______________
__  /_   _  __ \\_  ___/  _ \\_  __ \\____ \\_  _ \\  _ \\_  //_/  _ \\_  ___/
_  __/   / /_/ /  /   /  __/  / / /___/ //  __/  __/  ,<  /  __/  /    
/_/      \\____//_/    \\___//_/ /_//____/ \\___/\\___//_/|_| \\___//_/     
                                                                       
Platform Eksaminasi Forensik Digital Otomatis
by Stefanus Zen
"
    echo -e "\e[0m"
}

# Fungsi untuk menampilkan menu dengan tampilan yang lebih baik
show_menu() {
    while true; do
        print_header
        echo -e "\e[1;33m=== ForenSeeker ===\e[0m"
        echo -e "\e[1;37m1. Tampilkan Help"
        echo "2. Tampilkan Rules"
        echo "3. Keluar\e[0m"
        echo
        echo -n -e "\e[1;36mMasukkan pilihan Anda: \e[0m"
        read choice

        case $choice in
            1) show_help ;;
            2) show_rules ;;
            3) exit 0 ;;
            *) print_status "error" "Pilihan tidak valid" ;;
        esac
        echo
        read -p "Tekan Enter untuk melanjutkan..."
    done
}

# Fungsi utilitas
format_duration() {
    local duration=$1
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    if [ $minutes -eq 0 ]; then
        echo "$seconds detik"
    else
        echo "$minutes menit $seconds detik"
    fi
}

cleanup() {
    rm -rf results/*
    rm -f *_*.zip
    rm -f report_*.html
}

# Fungsi untuk menampilkan executive summary
create_executive_summary() {
    local type=$1
    local filename=$2
    local summary=""
    local summary_file="results/${type}/executive_summary.txt"
    
    # Buat direktori jika belum ada
    mkdir -p "results/${type}"
    
    # Buat file executive summary
    echo "=== Executive Summary ===" > $summary_file
    echo "File: $filename" >> $summary_file
    echo "Tanggal Eksaminasi: $(date '+%Y-%m-%d %H:%M:%S')" >> $summary_file
    echo "" >> $summary_file
    
    case $type in
        "image")
            echo "=== Eksaminasi Gambar ===" >> $summary_file
            
            # Metadata dari ExifTool
            if [ -f "results/images/exiftool_result.txt" ]; then
                echo "Metadata:" >> $summary_file
                grep -E "File Type|Image Size|Create Date|Modify Date" results/images/exiftool_result.txt | head -n 4 >> $summary_file
                echo "" >> $summary_file
            fi
            
            # Hash values
            if [ -f "results/images/sha256.txt" ]; then
                echo "Hash Values:" >> $summary_file
                echo "SHA256: $(cat results/images/sha256.txt | cut -d' ' -f1)" >> $summary_file
                echo "MD5: $(cat results/images/md5.txt | cut -d' ' -f1)" >> $summary_file
                echo "SHA1: $(cat results/images/sha1.txt | cut -d' ' -f1)" >> $summary_file
                echo "" >> $summary_file
            fi
            
            # Binwalk findings
            if [ -f "results/images/binwalk_result.txt" ]; then
                echo "Struktur File:" >> $summary_file
                grep -E "DECIMAL|HEXADECIMAL" results/images/binwalk_result.txt | head -n 3 >> $summary_file
                echo "" >> $summary_file
            fi
            
            # Aletheia findings
            if [ -f "results/images/aletheia_detection.txt" ]; then
                echo "Deteksi Manipulasi:" >> $summary_file
                head -n 5 results/images/aletheia_detection.txt >> $summary_file
            fi
            ;;
            
        "pcap")
            echo "=== Eksaminasi Jaringan ===" >> $summary_file
            
            # Protocol statistics
            if [ -f "results/pcap/tshark_analysis.txt" ]; then
                echo "Statistik Protokol:" >> $summary_file
                grep -A 5 "Protocol Hierarchy Statistics" results/pcap/tshark_analysis.txt | grep -v "Protocol" | head -n 3 >> $summary_file
                echo "" >> $summary_file
            fi
            
            # HTTP examination
            if [ -f "results/pcap/http_analysis.txt" ]; then
                echo "HTTP Traffic:" >> $summary_file
                grep -A 3 "HTTP Statistics" results/pcap/http_analysis.txt | grep -v "Statistics" | head -n 3 >> $summary_file
            fi
            
            # Hash values
            if [ -f "results/pcap/sha256.txt" ]; then
                echo "Hash Values:" >> $summary_file
                echo "SHA256: $(cat results/pcap/sha256.txt | cut -d' ' -f1)" >> $summary_file
                echo "MD5: $(cat results/pcap/md5.txt | cut -d' ' -f1)" >> $summary_file
                echo "SHA1: $(cat results/pcap/sha1.txt | cut -d' ' -f1)" >> $summary_file
                echo "" >> $summary_file
            fi
            ;;
            
        "memory")
            echo "=== Eksaminasi Memori ===" >> $summary_file
            
            # System information
            if [ -f "results/memory/vol_info.txt" ]; then
                echo "Informasi Sistem:" >> $summary_file
                grep -E "OS|Kernel|Architecture" results/memory/vol_info.txt | head -n 3 >> $summary_file
                echo "" >> $summary_file
            fi
            
            # Process list
            if [ -f "results/memory/vol_pslist.txt" ]; then
                echo "Proses Aktif:" >> $summary_file
                grep -v "Offset" results/memory/vol_pslist.txt | head -n 3 >> $summary_file
                echo "" >> $summary_file
            fi
            
            # Network connections
            if [ -f "results/memory/vol_netscan.txt" ]; then
                echo "Koneksi Jaringan:" >> $summary_file
                grep -v "Offset" results/memory/vol_netscan.txt | head -n 3 >> $summary_file
            fi
            
            # Hash values
            if [ -f "results/memory/sha256.txt" ]; then
                echo "Hash Values:" >> $summary_file
                echo "SHA256: $(cat results/memory/sha256.txt | cut -d' ' -f1)" >> $summary_file
                echo "MD5: $(cat results/memory/md5.txt | cut -d' ' -f1)" >> $summary_file
                echo "SHA1: $(cat results/memory/sha1.txt | cut -d' ' -f1)" >> $summary_file
                echo "" >> $summary_file
            fi
            ;;
            
        "filesystem")
            echo "=== Eksaminasi File Sistem ===" >> $summary_file
            
            # Partition information
            if [ -f "results/filesystem/mmls_output.txt" ]; then
                echo "Informasi Partisi:" >> $summary_file
                grep -v "Units" results/filesystem/mmls_output.txt | head -n 3 >> $summary_file
                echo "" >> $summary_file
            fi
            
            # File listing
            if [ -f "results/filesystem/fls_output.txt" ]; then
                echo "Daftar File Penting:" >> $summary_file
                grep -E "\.exe|\.dll|\.sys" results/filesystem/fls_output.txt | head -n 3 >> $summary_file
                echo "" >> $summary_file
            fi
            
            # Hash values
            if [ -f "results/filesystem/sha256.txt" ]; then
                echo "Hash Values:" >> $summary_file
                echo "SHA256: $(cat results/filesystem/sha256.txt | cut -d' ' -f1)" >> $summary_file
                echo "MD5: $(cat results/filesystem/md5.txt | cut -d' ' -f1)" >> $summary_file
                echo "SHA1: $(cat results/filesystem/sha1.txt | cut -d' ' -f1)" >> $summary_file
            fi
            ;;
    esac
    
    # Konversi ke HTML untuk ditampilkan di report
    summary="<h3>Executive Summary - Eksaminasi ${type^}</h3>"
    summary+="<p>File: $filename</p>"
    summary+="<pre>"
    summary+=$(cat $summary_file)
    summary+="</pre>"
    
    # Kembalikan summary untuk HTML report
    echo "$summary"
}

# Modifikasi fungsi create_report untuk menambahkan executive summary
create_report() {
    local filename=$1
    local type=$2
    local report_file="report_$(date +%Y%m%d_%H%M%S).html"
    
    # Buat file HTML report
    {
        echo "<html>
        <head>
            <title>Forensic Analysis Report</title>
            <style>
                :root {
                    --primary-color: #2c3e50;
                    --secondary-color: #3498db;
                    --accent-color: #e74c3c;
                    --background-color: #ecf0f1;
                    --text-color: #2c3e50;
                }
                
                pre.ascii-art {
                    font-family: monospace;
                    white-space: pre;
                    font-size: 14px;
                    color: var(--secondary-color);
                    margin: 20px 0;
                    text-shadow: 1px 1px 1px rgba(0,0,0,0.1);
                }
                
                .header {
                    text-align: center;
                    margin-bottom: 30px;
                    background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
                    padding: 20px;
                    border-radius: 10px;
                    color: white;
                    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
                }
                
                body {
                    padding: 20px;
                    font-family: 'Arial', sans-serif;
                    background-color: var(--background-color);
                    color: var(--text-color);
                    line-height: 1.6;
                    margin: 0;
                    padding: 20px;
                }
                
                h1, h2, h3, h4, h5 {
                    color: var(--primary-color);
                    margin-top: 20px;
                    line-height: 1.4;
                }
                
                h1 {
                    border-bottom: 3px solid var(--secondary-color);
                    padding-bottom: 10px;
                }
                
                hr {
                    border: none;
                    height: 2px;
                    background: linear-gradient(to right, var(--primary-color), var(--secondary-color));
                    margin: 20px 0;
                }
                
                pre {
                    color: var(--text-color);
                    background-color: white;
                    padding: 15px;
                    border-radius: 5px;
                    border-left: 4px solid var(--secondary-color);
                    overflow-x: auto;
                    margin: 10px 0;
                    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
                    font-size: 0.9em;
                    line-height: 1.4;
                }
                
                .result-section {
                    background-color: white;
                    padding: 20px;
                    margin: 20px 0;
                    border-radius: 8px;
                    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
                }
                
                .timestamp {
                    color: var(--accent-color);
                    font-style: italic;
                }
                
                .tool-header {
                    background-color: var(--primary-color);
                    padding: 10px 15px;
                    border-radius: 5px;
                    margin: 15px 0;
                }
                
                .tool-header h4 {
                    color: white !important;
                    margin: 0;
                    font-size: 1.2em;
                    font-weight: bold;
                    text-shadow: 1px 1px 1px rgba(0,0,0,0.2);
                }
                
                .container {
                    max-width: 1200px;
                    margin: 0 auto;
                    padding: 20px;
                }
                
                .sub-header {
                    margin: 10px 0;
                    padding: 5px 15px;
                    border-left: 4px solid var(--secondary-color);
                }
                
                .sub-header h5 {
                    color: var(--secondary-color);
                    margin: 5px 0;
                    font-size: 1.1em;
                    font-weight: normal;
                }
                
                .hash-section {
                    margin: 10px 0;
                    padding: 10px;
                    background-color: #f8f9fa;
                    border-radius: 5px;
                }
                
                .hash-section h6 {
                    color: var(--primary-color);
                    margin: 5px 0;
                    font-size: 1em;
                    font-weight: bold;
                }
            </style>
        </head>
        <body>
            <div class='container'>
                <div class='header'>
                    <pre class='ascii-art'>
__________                        ________         ______              
___  ____/__________________________  ___/____________  /______________
__  /_   _  __ \\_  ___/  _ \\_  __ \\____ \\_  _ \\  _ \\_  //_/  _ \\_  ___/
_  __/   / /_/ /  /   /  __/  / / /___/ //  __/  __/  ,<  /  __/  /    
/_/      \\____//_/    \\___//_/ /_//____/ \\___/\\___//_/|_| \\___//_/     
                    </pre>
                    <h2>Platform Eksaminasi Forensik Digital Otomatis</h2>
                    <p>by Stefanus Zen</p>
                </div>
                
                <h1>Forensic Examination Report</h1>
                
                <!-- Tambahkan Executive Summary -->
                <div class='result-section'>
                    $(create_executive_summary "$type" "$filename" 2>/dev/null)
                </div>
                
                <div class='result-section'>
                    <h2>Informasi File</h2>
                    <p><strong>Nama File:</strong> $filename</p>
                    <p class='timestamp'><strong>Tanggal Eksaminasi:</strong> $(date '+%Y-%m-%d %H:%M:%S')</p>
                </div>
                
                <hr>
                
                <h3>Hasil Eksaminasi Detail:</h3>"
    } > "$report_file"
    
    # Fungsi untuk menambahkan hasil eksaminasi ke report
    add_analysis_section() {
        local title=$1
        local subtitle=$2
        local result_file=$3
        
        if [ -f "$result_file" ]; then
            echo "<div class='result-section'>
                <div class='tool-header'>
                    <h4>$title</h4>
                </div>
                <div class='sub-header'>
                    <h5>$subtitle</h5>
                </div>
                <pre>" >> $report_file
            cat "$result_file" >> $report_file
            echo "</pre></div>" >> $report_file
        fi
    }

    # Menambahkan hasil berdasarkan tipe eksaminasi
    case $type in
        "image")
            # File Hash Results
            add_analysis_section "File Hash Examination" "Nilai Hash SHA256" "results/images/sha256.txt"
            add_analysis_section "MD5 Hash" "Nilai Hash MD5" "results/images/md5.txt"
            add_analysis_section "SHA1 Hash" "Nilai Hash SHA1" "results/images/sha1.txt"
            
            # ExifTool Results
            add_analysis_section "ExifTool Examination" "Hasil Pemeriksaan Metadata File" "results/images/exiftool_result.txt"
            
            # Binwalk Results
            add_analysis_section "Binwalk Examination" "Hasil Pemeriksaan Struktur File" "results/images/binwalk_result.txt"
            
            # ImageMagick Results
            add_analysis_section "ImageMagick Examination" "Hasil Pemeriksaan Properti Gambar" "results/images/imagemagick_info.txt"
            
            # Aletheia Results
            add_analysis_section "Aletheia Examination" "Hasil Deteksi Manipulasi" "results/images/aletheia_detection.txt"
            ;;
            
        "pcap")
            # File Hash Results
            add_analysis_section "File Hash Examination" "Nilai Hash SHA256" "results/pcap/sha256.txt"
            add_analysis_section "MD5 Hash" "Nilai Hash MD5" "results/pcap/md5.txt"
            add_analysis_section "SHA1 Hash" "Nilai Hash SHA1" "results/pcap/sha1.txt"
            
            # TShark Results
            add_analysis_section "TShark Examination" "Hasil Pemeriksaan Paket Jaringan" "results/pcap/tshark_analysis.txt"
            add_analysis_section "HTTP Examination" "Hasil Pemeriksaan Lalu Lintas HTTP" "results/pcap/http_analysis.txt"
            
            # NetworkMiner Results
            if [ -d "results/pcap/networkminer" ]; then
                add_analysis_section "NetworkMiner Examination" "Hasil Pemeriksaan NetworkMiner" "results/pcap/networkminer/summary.txt"
            fi
            
            # BruteShark Results
            if [ -d "results/pcap/bruteshark" ]; then
                add_analysis_section "BruteShark Examination" "Hasil Pemeriksaan BruteShark" "results/pcap/bruteshark/summary.txt"
            fi
            ;;
            
        "memory")
            # File Hash Results
            add_analysis_section "File Hash Examination" "Nilai Hash SHA256" "results/memory/sha256.txt"
            add_analysis_section "MD5 Hash" "Nilai Hash MD5" "results/memory/md5.txt"
            add_analysis_section "SHA1 Hash" "Nilai Hash SHA1" "results/memory/sha1.txt"
            
            # Volatility Results
            add_analysis_section "Volatility System Info" "Informasi Sistem" "results/memory/vol_info.txt"
            add_analysis_section "Volatility Process List" "Daftar Proses" "results/memory/vol_pslist.txt"
            add_analysis_section "Volatility Network Scan" "Hasil Pemeriksaan Jaringan" "results/memory/vol_netscan.txt"
            add_analysis_section "Volatility Command Line" "Command Line History" "results/memory/vol_cmdline.txt"
            add_analysis_section "Volatility Malware Find" "Hasil Pencarian Malware" "results/memory/vol_malfind.txt"
            
            # Rekall Results
            add_analysis_section "Rekall Process List" "Daftar Proses dari Rekall" "results/memory/rekall_pslist.txt"
            add_analysis_section "Rekall Network Scan" "Hasil Pemeriksaan Jaringan Rekall" "results/memory/rekall_netscan.txt"
            add_analysis_section "Rekall Malware Find" "Hasil Pencarian Malware Rekall" "results/memory/rekall_malfind.txt"
            ;;
            
        "filesystem")
            # File Hash Results
            add_analysis_section "File Hash Examination" "Nilai Hash SHA256" "results/filesystem/sha256.txt"
            add_analysis_section "MD5 Hash" "Nilai Hash MD5" "results/filesystem/md5.txt"
            add_analysis_section "SHA1 Hash" "Nilai Hash SHA1" "results/filesystem/sha1.txt"
            
            # TSK Results
            add_analysis_section "Partition Examination" "Hasil Pemeriksaan Partisi" "results/filesystem/mmls_output.txt"
            add_analysis_section "File Listing" "Daftar File Sistem" "results/filesystem/fls_output.txt"
            
            # String Results
            add_analysis_section "Strings Examination" "Hasil Ekstraksi String" "results/filesystem/strings_output.txt"
            
            # Binwalk Results
            add_analysis_section "Binwalk Examination" "Hasil Pemeriksaan Struktur File" "results/filesystem/binwalk_output.txt"
            
            # XXD Results
            add_analysis_section "Hex Dump Examination" "Hasil Pemeriksaan Hex Dump" "results/filesystem/xxd_hexdump.txt"
            add_analysis_section "Hex Dump Preview" "Preview 1000 Bytes Pertama" "results/filesystem/xxd_preview.txt"
            ;;
    esac

    echo "</div></body></html>" >> $report_file
    echo "$report_file"
}

# Fungsi Telegram
send_telegram_message() {
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d text="$1" > /dev/null 2>&1
}

send_telegram_file() {
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendDocument" \
        -F chat_id="$TELEGRAM_CHAT_ID" \
        -F document=@"$1" > /dev/null 2>&1
}

# Fungsi menu
show_help() {
    echo "Penggunaan: sudo ./forenseeker.sh -[parameter] [file]"
    echo "Parameter:"
    echo "  -img   : Eksaminasi file gambar"
    echo "  -pcap  : Eksaminasi file jaringan"
    echo "  -mem   : Eksaminasi file memori"
    echo "  -f     : Eksaminasi file sistem"
    echo
    echo "Contoh: sudo ./forenseeker.sh -img evidence.jpg"
}

show_rules() {
    echo "Rules penggunaan platform:"
    echo "1. Pastikan mengatur hak akses untuk platform dengan perintah: chmod +x ./forenseeker.sh"
    echo "2. Pilih parameter yang sesuai dengan jenis file yang dimasukkan"
    echo "3. Pastikan file evidence yang akan dieksaminasi berada dalam direktori yang sama"
    echo "4. Jalankan platform dengan akses root (sudo)"
}

# Modifikasi fungsi check_required_tools
check_required_tools() {
    local type=$1
    local required_tools=()
    local missing_tools=()
    
    print_status "info" "Memeriksa tools yang diperlukan..."
    
    case $type in
        "image")
            required_tools=("exiftool" "binwalk" "foremost" "zsteg" "convert" "aletheia")
            ;;
        "pcap")
            required_tools=("tshark" "bruteshark-cli")
            ;;
        "memory")
            required_tools=("vol3" "rekall")
            ;;
        "filesystem")
            required_tools=("mmls" "fls" "foremost" "bulk_extractor" "strings" "binwalk" "xxd")
            ;;
    esac
    
    local total_tools=${#required_tools[@]}
    local current_tool=0
    
    for tool in "${required_tools[@]}"; do
        current_tool=$((current_tool + 1))
        show_progress $current_tool $total_tools
        
        if ! command -v $tool &> /dev/null; then
            missing_tools+=($tool)
        fi
    done
    echo
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_status "warning" "Beberapa tools tidak tersedia:"
        for tool in "${missing_tools[@]}"; do
            echo -e "  - \e[1;33m$tool\e[0m"
        done
        print_status "info" "Eksaminasi akan tetap dilanjutkan dengan tools yang tersedia"
        send_telegram_message "Warning: Beberapa tools tidak tersedia: ${missing_tools[*]}"
    else
        print_status "success" "Semua tools yang diperlukan tersedia"
    fi
    
    return 0
}

# Modifikasi fungsi analyze_image untuk tampilan yang lebih baik
analyze_image() {
    local file=$1
    mkdir -p results/images
    
    print_header
    print_status "info" "Memulai proses eksaminasi forensik file gambar: $file"
    send_telegram_message "Memulai proses eksaminasi forensik file gambar: $file"
    start_time=$(date +%s)
    
    # Generate timestamp for zip filename
    local timestamp=$(date +%Y%m%d)
    local zip_name="image_$(basename "$file" | cut -d'.' -f1)_${timestamp}.zip"
    
    # Hash Examination
    if command -v sha256sum &> /dev/null; then
        print_status "info" "Melakukan hash examination..."
        send_telegram_message "Memulai proses hash examination..."
        tool_start=$(date +%s)
        sha256sum $file > results/images/sha256.txt
        md5sum $file > results/images/md5.txt
        sha1sum $file > results/images/sha1.txt
        tool_end=$(date +%s)
        tool_duration=$((tool_end - tool_start))
        print_status "success" "Hash examination selesai dalam $(format_duration $tool_duration)"
        send_telegram_message "Proses hash examination selesai dalam $(format_duration $tool_duration)"
    fi
    
    # ExifTool Examination
    if command -v exiftool &> /dev/null; then
        print_status "info" "Melakukan eksaminasi dengan ExifTool..."
        send_telegram_message "Memulai eksaminasi dengan ExifTool..."
        tool_start=$(date +%s)
        exiftool $file > results/images/exiftool_result.txt
        tool_end=$(date +%s)
        tool_duration=$((tool_end - tool_start))
        print_status "success" "Eksaminasi ExifTool selesai dalam $(format_duration $tool_duration)"
        send_telegram_message "Eksaminasi ExifTool selesai dalam $(format_duration $tool_duration)"
    fi
    
    # Binwalk Examination
    if command -v binwalk &> /dev/null; then
        print_status "info" "Melakukan eksaminasi dengan Binwalk..."
        send_telegram_message "Memulai eksaminasi dengan Binwalk..."
        tool_start=$(date +%s)
        binwalk $file > results/images/binwalk_result.txt 2>/dev/null
        binwalk -e $file -C results/images/binwalk_extracted/ 2>/dev/null
        tool_end=$(date +%s)
        tool_duration=$((tool_end - tool_start))
        print_status "success" "Eksaminasi Binwalk selesai dalam $(format_duration $tool_duration)"
        send_telegram_message "Eksaminasi Binwalk selesai dalam $(format_duration $tool_duration)"
    fi
    
    # Foremost Examination
    if command -v foremost &> /dev/null; then
        print_status "info" "Melakukan eksaminasi dengan Foremost..."
        send_telegram_message "Memulai eksaminasi dengan Foremost..."
        tool_start=$(date +%s)
        foremost -i $file -o results/images/foremost_output
        tool_end=$(date +%s)
        tool_duration=$((tool_end - tool_start))
        print_status "success" "Eksaminasi Foremost selesai dalam $(format_duration $tool_duration)"
        send_telegram_message "Eksaminasi Foremost selesai dalam $(format_duration $tool_duration)"
    fi
    
    # Zsteg Examination
    if command -v zsteg &> /dev/null; then
        print_status "info" "Melakukan eksaminasi dengan Zsteg..."
        send_telegram_message "Memulai eksaminasi dengan Zsteg..."
        tool_start=$(date +%s)
        zsteg $file > results/images/zsteg_result.txt
        tool_end=$(date +%s)
        tool_duration=$((tool_end - tool_start))
        print_status "success" "Eksaminasi Zsteg selesai dalam $(format_duration $tool_duration)"
        send_telegram_message "Eksaminasi Zsteg selesai dalam $(format_duration $tool_duration)"
    fi
    
    # ImageMagick Examination
    if command -v convert &> /dev/null; then
        print_status "info" "Melakukan eksaminasi dengan ImageMagick..."
        send_telegram_message "Memulai eksaminasi dengan ImageMagick..."
        tool_start=$(date +%s)
        identify -verbose $file > results/images/imagemagick_info.txt
        convert $file -print "%[EXIF:*]" results/images/imagemagick_metadata.txt
        convert $file -auto-level results/images/auto_level.jpg
        convert $file -equalize results/images/equalized.jpg
        convert $file -normalize results/images/normalized.jpg
        convert $file -analyze results/images/analysis.txt
        tool_end=$(date +%s)
        tool_duration=$((tool_end - tool_start))
        print_status "success" "Eksaminasi ImageMagick selesai dalam $(format_duration $tool_duration)"
        send_telegram_message "Eksaminasi ImageMagick selesai dalam $(format_duration $tool_duration)"
    fi
    
    # Aletheia Examination
    if command -v aletheia &> /dev/null; then
        print_status "info" "Melakukan eksaminasi dengan Aletheia..."
        send_telegram_message "Memulai eksaminasi dengan Aletheia..."
        tool_start=$(date +%s)
        aletheia detect -i $file -o results/images/aletheia_detection.txt
        aletheia ela -i $file -o results/images/aletheia_ela.png
        aletheia lg -i $file -o results/images/aletheia_lg.png
        aletheia meta -i $file -o results/images/aletheia_metadata.txt
        tool_end=$(date +%s)
        tool_duration=$((tool_end - tool_start))
        print_status "success" "Eksaminasi Aletheia selesai dalam $(format_duration $tool_duration)"
        send_telegram_message "Eksaminasi Aletheia selesai dalam $(format_duration $tool_duration)"
    fi
    
    # Total time calculation
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    print_status "info" "Membuat executive summary..."
    create_executive_summary "image" "$file"
    
    if [ -f "results/images/executive_summary.txt" ]; then
        print_status "success" "Executive summary berhasil dibuat"
        send_telegram_message "Executive Summary:"
        send_telegram_file "results/images/executive_summary.txt"
    fi
    
    print_status "info" "Membuat laporan HTML..."
    report_file=$(create_report "$file" "image")
    
    print_status "info" "Membuat file zip hasil eksaminasi..."
    zip -r "$zip_name" results/images/ "$report_file" > /dev/null
    
    print_status "success" "Proses eksaminasi forensik file gambar $file selesai dalam $(format_duration $duration)"
    send_telegram_message "Proses eksaminasi forensik file gambar $file selesai dalam $(format_duration $duration)"
    send_telegram_file "$zip_name"
}

analyze_pcap() {
    local file=$1
    mkdir -p results/pcap
    
    print_header
    print_status "info" "Memulai proses eksaminasi forensik file PCAP: $file"
    send_telegram_message "Memulai proses eksaminasi forensik file PCAP: $file"
    
    start_time=$(date +%s)
    
    # Generate timestamp for zip filename
    local timestamp=$(date +%Y%m%d)
    local zip_name="pcap_$(basename "$file" | cut -d'.' -f1)_${timestamp}.zip"
    
    # Hash Examination
    print_status "info" "Melakukan hash examination..."
    send_telegram_message "Memulai proses hash examination..."
    tool_start=$(date +%s)
    sha256sum $file > results/pcap/sha256.txt
    md5sum $file > results/pcap/md5.txt
    sha1sum $file > results/pcap/sha1.txt
    tool_end=$(date +%s)
    tool_duration=$((tool_end - tool_start))
    print_status "success" "Hash examination selesai dalam $(format_duration $tool_duration)"
    send_telegram_message "Proses hash examination selesai dalam $(format_duration $tool_duration)"
    
    # Tshark Examination
    print_status "info" "Melakukan eksaminasi dengan Tshark..."
    send_telegram_message "Memulai eksaminasi dengan Tshark..."
    tool_start=$(date +%s)
    tshark -r $file -q -z io,phs -z conv,ip -z expert > results/pcap/tshark_analysis.txt
    tshark -r $file -q -z http,tree > results/pcap/http_analysis.txt
    tool_end=$(date +%s)
    tool_duration=$((tool_end - tool_start))
    print_status "success" "Eksaminasi Tshark selesai dalam $(format_duration $tool_duration)"
    send_telegram_message "Eksaminasi Tshark selesai dalam $(format_duration $tool_duration)"
    
    # NetworkMiner Examination
    print_status "info" "Melakukan eksaminasi dengan NetworkMiner..."
    send_telegram_message "Memulai eksaminasi dengan NetworkMiner..."
    tool_start=$(date +%s)
    mono ~/tools/NetworkMiner/NetworkMiner.exe -r $file -o results/pcap/networkminer/
    tool_end=$(date +%s)
    tool_duration=$((tool_end - tool_start))
    print_status "success" "Eksaminasi NetworkMiner selesai dalam $(format_duration $tool_duration)"
    send_telegram_message "Eksaminasi NetworkMiner selesai dalam $(format_duration $tool_duration)"
    
    # BruteShark Examination
    print_status "info" "Melakukan eksaminasi dengan BruteShark..."
    send_telegram_message "Memulai eksaminasi dengan BruteShark..."
    tool_start=$(date +%s)
    bruteshark-cli -f $file -o results/pcap/bruteshark/
    tool_end=$(date +%s)
    tool_duration=$((tool_end - tool_start))
    print_status "success" "Eksaminasi BruteShark selesai dalam $(format_duration $tool_duration)"
    send_telegram_message "Eksaminasi BruteShark selesai dalam $(format_duration $tool_duration)"
    
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    print_status "info" "Membuat executive summary..."
    create_executive_summary "pcap" "$file"
    if [ -f "results/pcap/executive_summary.txt" ]; then
        print_status "success" "Executive summary berhasil dibuat"
        send_telegram_message "Executive Summary:"
        send_telegram_file "results/pcap/executive_summary.txt"
    fi
    
    print_status "info" "Membuat laporan HTML..."
    report_file=$(create_report "$file" "pcap")
    
    print_status "info" "Membuat file zip hasil eksaminasi..."
    zip -r "$zip_name" results/pcap/ "$report_file" > /dev/null
    
    print_status "success" "Proses eksaminasi forensik file PCAP $file selesai dalam $(format_duration $duration)"
    send_telegram_message "Proses eksaminasi forensik file PCAP $file selesai dalam $(format_duration $duration)"
    send_telegram_file "$zip_name"
}

analyze_memory() {
    local file=$1
    mkdir -p results/memory
    
    print_header
    print_status "info" "Memulai proses eksaminasi forensik file memori: $file"
    send_telegram_message "Memulai proses eksaminasi forensik file memori: $file"
    
    start_time=$(date +%s)
    
    # Generate timestamp for zip filename
    local timestamp=$(date +%Y%m%d)
    local zip_name="memory_$(basename "$file" | cut -d'.' -f1)_${timestamp}.zip"
    
    # Hash Examination
    print_status "info" "Melakukan hash examination..."
    send_telegram_message "Memulai proses hash examination..."
    tool_start=$(date +%s)
    sha256sum $file > results/memory/sha256.txt
    md5sum $file > results/memory/md5.txt
    sha1sum $file > results/memory/sha1.txt
    tool_end=$(date +%s)
    tool_duration=$((tool_end - tool_start))
    print_status "success" "Hash examination selesai dalam $(format_duration $tool_duration)"
    send_telegram_message "Proses hash examination selesai dalam $(format_duration $tool_duration)"
    
    # Volatility Examination
    print_status "info" "Melakukan eksaminasi dengan Volatility..."
    send_telegram_message "Memulai eksaminasi dengan Volatility..."
    tool_start=$(date +%s)
    vol3 -f $file windows.info > results/memory/vol_info.txt
    vol3 -f $file windows.pslist > results/memory/vol_pslist.txt
    vol3 -f $file windows.netscan > results/memory/vol_netscan.txt
    vol3 -f $file windows.cmdline > results/memory/vol_cmdline.txt
    vol3 -f $file windows.malfind > results/memory/vol_malfind.txt
    tool_end=$(date +%s)
    tool_duration=$((tool_end - tool_start))
    print_status "success" "Eksaminasi Volatility selesai dalam $(format_duration $tool_duration)"
    send_telegram_message "Eksaminasi Volatility selesai dalam $(format_duration $tool_duration)"
    
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    print_status "info" "Membuat executive summary..."
    create_executive_summary "memory" "$file"
    if [ -f "results/memory/executive_summary.txt" ]; then
        print_status "success" "Executive summary berhasil dibuat"
        send_telegram_message "Executive Summary:"
        send_telegram_file "results/memory/executive_summary.txt"
    fi
    
    print_status "info" "Membuat laporan HTML..."
    report_file=$(create_report "$file" "memory")
    zip -r "$zip_name" results/memory/ "$report_file" > /dev/null
    
    print_status "success" "Proses eksaminasi forensik file memori $file selesai dalam $(format_duration $duration)"
    send_telegram_message "Proses eksaminasi forensik file memori $file selesai dalam $(format_duration $duration)"
    send_telegram_file "$zip_name"
}

analyze_filesystem() {
    local file=$1
    mkdir -p results/filesystem
    
    print_header
    print_status "info" "Memulai proses eksaminasi forensik file sistem: $file"
    send_telegram_message "Memulai proses eksaminasi forensik file sistem: $file"
    
    start_time=$(date +%s)
    
    # Generate timestamp for zip filename
    local timestamp=$(date +%Y%m%d)
    local zip_name="filesystem_$(basename "$file" | cut -d'.' -f1)_${timestamp}.zip"
    
    # Hash Examination
    print_status "info" "Melakukan hash examination..."
    send_telegram_message "Memulai proses hash examination..."
    tool_start=$(date +%s)
    sha256sum $file > results/filesystem/sha256.txt
    md5sum $file > results/filesystem/md5.txt
    sha1sum $file > results/filesystem/sha1.txt
    tool_end=$(date +%s)
    tool_duration=$((tool_end - tool_start))
    print_status "success" "Hash examination selesai dalam $(format_duration $tool_duration)"
    send_telegram_message "Proses hash examination selesai dalam $(format_duration $tool_duration)"
    
    # TSK Examination
    print_status "info" "Melakukan eksaminasi dengan The Sleuth Kit..."
    send_telegram_message "Memulai eksaminasi dengan The Sleuth Kit..."
    tool_start=$(date +%s)
    mmls $file > results/filesystem/mmls_output.txt
    fls -r $file > results/filesystem/fls_output.txt
    tool_end=$(date +%s)
    tool_duration=$((tool_end - tool_start))
    print_status "success" "Eksaminasi TSK selesai dalam $(format_duration $tool_duration)"
    send_telegram_message "Eksaminasi TSK selesai dalam $(format_duration $tool_duration)"
    
    # Foremost Examination
    print_status "info" "Melakukan eksaminasi dengan Foremost..."
    send_telegram_message "Memulai eksaminasi dengan Foremost..."
    tool_start=$(date +%s)
    foremost -t all -i $file -o results/filesystem/foremost_output
    tool_end=$(date +%s)
    tool_duration=$((tool_end - tool_start))
    print_status "success" "Eksaminasi Foremost selesai dalam $(format_duration $tool_duration)"
    send_telegram_message "Eksaminasi Foremost selesai dalam $(format_duration $tool_duration)"
    
    # Bulk Extractor Examination
    print_status "info" "Melakukan eksaminasi dengan Bulk Extractor..."
    send_telegram_message "Memulai eksaminasi dengan Bulk Extractor..."
    tool_start=$(date +%s)
    bulk_extractor $file -o results/filesystem/bulk_extractor_output
    tool_end=$(date +%s)
    tool_duration=$((tool_end - tool_start))
    print_status "success" "Eksaminasi Bulk Extractor selesai dalam $(format_duration $tool_duration)"
    send_telegram_message "Eksaminasi Bulk Extractor selesai dalam $(format_duration $tool_duration)"
    
    # Strings Examination
    print_status "info" "Melakukan eksaminasi dengan Strings..."
    send_telegram_message "Memulai eksaminasi dengan Strings..."
    tool_start=$(date +%s)
    strings $file > results/filesystem/strings_output.txt
    tool_end=$(date +%s)
    tool_duration=$((tool_end - tool_start))
    print_status "success" "Eksaminasi Strings selesai dalam $(format_duration $tool_duration)"
    send_telegram_message "Eksaminasi Strings selesai dalam $(format_duration $tool_duration)"
    
    # Binwalk Examination
    print_status "info" "Melakukan eksaminasi dengan Binwalk..."
    send_telegram_message "Memulai eksaminasi dengan Binwalk..."
    tool_start=$(date +%s)
    binwalk $file > results/filesystem/binwalk_output.txt 2>/dev/null
    binwalk -e $file -C results/filesystem/binwalk_extracted/ 2>/dev/null
    tool_end=$(date +%s)
    tool_duration=$((tool_end - tool_start))
    print_status "success" "Eksaminasi Binwalk selesai dalam $(format_duration $tool_duration)"
    send_telegram_message "Eksaminasi Binwalk selesai dalam $(format_duration $tool_duration)"
    
    # XXD Examination
    print_status "info" "Melakukan eksaminasi dengan XXD..."
    send_telegram_message "Memulai eksaminasi dengan XXD..."
    tool_start=$(date +%s)
    xxd $file > results/filesystem/xxd_hexdump.txt
    head -c 1000 $file | xxd > results/filesystem/xxd_preview.txt
    tool_end=$(date +%s)
    tool_duration=$((tool_end - tool_start))
    print_status "success" "Eksaminasi XXD selesai dalam $(format_duration $tool_duration)"
    send_telegram_message "Eksaminasi XXD selesai dalam $(format_duration $tool_duration)"
    
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    print_status "info" "Membuat executive summary..."
    create_executive_summary "filesystem" "$file"
    if [ -f "results/filesystem/executive_summary.txt" ]; then
        print_status "success" "Executive summary berhasil dibuat"
        send_telegram_message "Executive Summary:"
        send_telegram_file "results/filesystem/executive_summary.txt"
    fi
    
    print_status "info" "Membuat laporan HTML..."
    report_file=$(create_report "$file" "filesystem")
    zip -r "$zip_name" results/filesystem/ "$report_file" > /dev/null
    
    print_status "success" "Proses eksaminasi forensik file sistem $file selesai dalam $(format_duration $duration)"
    send_telegram_message "Proses eksaminasi forensik file sistem $file selesai dalam $(format_duration $duration)"
    send_telegram_file "$zip_name"
}

# Setup trap untuk cleanup
trap cleanup EXIT

# Main script
if [ "$1" == "" ]; then
    show_menu
else
    case $1 in
        -img) 
            check_required_tools "image" && analyze_image $2 ;;
        -pcap) 
            check_required_tools "pcap" && analyze_pcap $2 ;;
        -mem) 
            check_required_tools "memory" && analyze_memory $2 ;;
        -f) 
            check_required_tools "filesystem" && analyze_filesystem $2 ;;
        *) 
            show_help ;;
    esac
fi
