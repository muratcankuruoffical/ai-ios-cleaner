#!/bin/bash

# AI Cleaner iOS - Xcode Temizlik ve Kurulum Script
# Bu script tüm bozuk Xcode dosyalarını temizler ve rehberi gösterir

set -e

echo "🧹 AI Cleaner iOS - Xcode Temizleme Başlatılıyor..."
echo ""

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Mevcut dizini kontrol et
if [ ! -d "AI Cleaner" ]; then
    echo -e "${RED}❌ Hata: 'AI Cleaner' klasörü bulunamadı.${NC}"
    echo "Bu scripti ai-ios-cleaner klasöründe çalıştırmalısınız."
    exit 1
fi

echo -e "${BLUE}📍 Çalışma dizini: $(pwd)${NC}"
echo ""

# 1. Xcode'un bozuk proje dosyalarını temizle
echo -e "${YELLOW}1️⃣  Bozuk Xcode projelerini temizliyorum...${NC}"
if [ -d "AI Cleaner.xcodeproj" ]; then
    rm -rf "AI Cleaner.xcodeproj"
    echo "   ✅ AI Cleaner.xcodeproj silindi"
fi
if [ -d "AI Cleaner.xcworkspace" ]; then
    rm -rf "AI Cleaner.xcworkspace"
    echo "   ✅ AI Cleaner.xcworkspace silindi"
fi

# 2. DerivedData temizle
echo ""
echo -e "${YELLOW}2️⃣  DerivedData temizleniyor...${NC}"
if [ -d ~/Library/Developer/Xcode/DerivedData ]; then
    rm -rf ~/Library/Developer/Xcode/DerivedData/AI_Cleaner-*
    rm -rf ~/Library/Developer/Xcode/DerivedData/AI\ Cleaner-*
    echo "   ✅ DerivedData temizlendi"
else
    echo "   ⚠️  DerivedData bulunamadı (normal olabilir)"
fi

# 3. Xcode cache temizle
echo ""
echo -e "${YELLOW}3️⃣  Xcode cache temizleniyor...${NC}"
if [ -d ~/Library/Caches/com.apple.dt.Xcode ]; then
    rm -rf ~/Library/Caches/com.apple.dt.Xcode
    echo "   ✅ Xcode cache temizlendi"
fi

# 4. Manuel taşınmış dosyaları kontrol et ve temizle
echo ""
echo -e "${YELLOW}4️⃣  Manuel taşınmış dosyaları kontrol ediyorum...${NC}"

# Eğer Xcode içinde AI Cleaner klasörü varsa (yanlış taşıma)
if [ -d "AI Cleaner/AI Cleaner" ]; then
    echo "   ⚠️  İç içe 'AI Cleaner' klasörü bulundu - düzeltiliyor..."
    # Backup oluştur
    if [ -d "AI Cleaner.backup" ]; then
        rm -rf "AI Cleaner.backup"
    fi
    cp -r "AI Cleaner" "AI Cleaner.backup"
    echo "   ✅ Backup oluşturuldu: AI Cleaner.backup"
fi

echo ""
echo -e "${GREEN}✅ Temizlik tamamlandı!${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${BLUE}📋 Şimdi ne yapmalısınız:${NC}"
echo ""
echo "1️⃣  Xcode'u tamamen kapatın (⌘Q)"
echo ""
echo "2️⃣  Mac'i yeniden başlatın (önerilir) veya sadece Xcode'u açın"
echo ""
echo "3️⃣  Bu komutu çalıştırın:"
echo -e "   ${GREEN}open SETUP-SIMPLE.md${NC}"
echo ""
echo "4️⃣  SETUP-SIMPLE.md'deki BASİTLEŞTİRİLMİŞ adımları izleyin"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${YELLOW}⚠️  Xcode'u şimdi kapatıyorum (3 saniye)...${NC}"
sleep 1
echo "3..."
sleep 1
echo "2..."
sleep 1
echo "1..."

# Xcode'u kapat
killall Xcode 2>/dev/null || echo "   ℹ️  Xcode zaten kapalı"

echo ""
echo -e "${GREEN}✨ Hazırsınız! Şimdi SETUP-SIMPLE.md dosyasını açın.${NC}"
