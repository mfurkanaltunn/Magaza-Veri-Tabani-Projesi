/*
PROJE ADI: Mağaza Stok ve Satış Yönetim Sistemi
YAZAN: M. Furkan Altun
TARIH: Ocak 2026
AÇIKLAMA: Bu proje, bir perakende mağazasının envanter, müşteri ve satış süreçlerini yönetmek 
amacıyla MsSQL (T-SQL) kullanılarak geliştirilmiştir. 
Proje; Veri Normalizasyonu, İlişkisel Veritabanı Tasarımı (Primary/Foreign Key) ve 
kapsamlı veri manipülasyonu (CRUD) işlemlerini içerir.
*/

-- =============================================
-- 1. VERİTABANI OLUŞTURMA
-- =============================================
CREATE DATABASE MagazaDB;
GO
USE MagazaDB;
GO

-- =============================================
-- 2. TABLOLARIN OLUŞTURULMASI (DDL)
-- Normalizasyon kurallarına uygun ilişkisel yapı
-- =============================================

-- Müşteriler Tablosu
CREATE TABLE Musteriler (
    MusteriID INT PRIMARY KEY IDENTITY(1,1),
    Ad NVARCHAR(50) NOT NULL,
    Soyad NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) UNIQUE,
    Sehir NVARCHAR(50),
    KayitTarihi DATETIME DEFAULT GETDATE()
);

-- Kategoriler Tablosu (Ürünleri normalize etmek için ayrıldı)
CREATE TABLE Kategoriler (
    KategoriID INT PRIMARY KEY IDENTITY(1,1),
    KategoriAdi NVARCHAR(50) NOT NULL
);

-- Ürünler Tablosu (Kategori ile ilişkilendirilmiş)
CREATE TABLE Urunler (
    UrunID INT PRIMARY KEY IDENTITY(1,1),
    UrunAdi NVARCHAR(100) NOT NULL,
    KategoriID INT, -- Foreign Key
    Fiyat DECIMAL(18, 2) NOT NULL,
    StokMiktari INT DEFAULT 0,
    CONSTRAINT FK_Urun_Kategori FOREIGN KEY (KategoriID) REFERENCES Kategoriler(KategoriID)
);

-- Satışlar Tablosu (Müşteri ve Ürün arasındaki ilişkiyi kurar)
CREATE TABLE Satislar (
    SatisID INT PRIMARY KEY IDENTITY(1,1),
    MusteriID INT, -- Foreign Key
    UrunID INT,    -- Foreign Key
    Adet INT NOT NULL,
    ToplamTutar DECIMAL(18, 2),
    SatisTarihi DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Satis_Musteri FOREIGN KEY (MusteriID) REFERENCES Musteriler(MusteriID),
    CONSTRAINT FK_Satis_Urun FOREIGN KEY (UrunID) REFERENCES Urunler(UrunID)
);

-- =============================================
-- 3. ÖRNEK VERİ GİRİŞLERİ (INSERT - DML)
-- Sistemin test edilmesi için dummy data girişi
-- =============================================

-- Kategorilerin Eklenmesi
INSERT INTO Kategoriler (KategoriAdi) VALUES ('Elektronik'), ('Giyim'), ('Kitap'), ('Kırtasiye');

-- Ürünlerin Eklenmesi
INSERT INTO Urunler (UrunAdi, KategoriID, Fiyat, StokMiktari) VALUES 
('Laptop', 1, 25000.00, 10),
('Python Eğitim Kitabı', 3, 450.00, 50),
('Kablosuz Kulaklık', 1, 1500.00, 30),
('Tükenmez Kalem', 4, 25.00, 100);

-- Müşterilerin Eklenmesi
INSERT INTO Musteriler (Ad, Soyad, Sehir, Email) VALUES 
('Ahmet', 'Yılmaz', 'İstanbul', 'ahmet.y@mail.com'),
('Ayşe', 'Demir', 'Ankara', 'ayse.d@mail.com'),
('Mehmet', 'Kaya', 'İzmir', 'mehmet.k@mail.com');

-- Satış İşlemlerinin Simülasyonu
INSERT INTO Satislar (MusteriID, UrunID, Adet, ToplamTutar) VALUES 
(1, 2, 1, 450.00),   -- Ahmet Bey Kitap aldı
(2, 1, 1, 25000.00), -- Ayşe Hanım Laptop aldı
(3, 3, 2, 3000.00);  -- Mehmet Bey 2 tane Kulaklık aldı

-- =============================================
-- 4. RAPORLAMA VE ANALİZ (SELECT & JOIN - DQL)
-- Verilerin anlamlı hale getirilmesi
-- =============================================

/* RAPOR 1: Detaylı Satış Raporu (JOIN Kullanımı)
Hangi müşteri, hangi kategoriden, hangi ürünü, ne zaman aldı?
*/
SELECT 
    M.Ad + ' ' + M.Soyad AS MusteriAdi,
    U.UrunAdi,
    K.KategoriAdi,
    S.Adet,
    S.ToplamTutar,
    S.SatisTarihi
FROM Satislar S
INNER JOIN Musteriler M ON S.MusteriID = M.MusteriID
INNER JOIN Urunler U ON S.UrunID = U.UrunID
INNER JOIN Kategoriler K ON U.KategoriID = K.KategoriID;

/* RAPOR 2: Stok Kritik Seviye Kontrolü
Stok miktarı 20'nin altına düşen ürünleri listeler.
*/
SELECT UrunAdi, StokMiktari 
FROM Urunler 
WHERE StokMiktari < 20;

-- =============================================
-- 5. VERİ MANİPÜLASYONU (UPDATE & DELETE - DML)
-- Veri güncelleme ve temizleme senaryoları
-- =============================================

-- SENARYO 1: Fiyat Güncelleme (Enflasyon Zammı)
-- Laptop fiyatlarını %10 artırıyoruz.
UPDATE Urunler 
SET Fiyat = Fiyat * 1.10 
WHERE UrunAdi = 'Laptop';

-- SENARYO 2: Stok Düşürme (Satış Sonrası)
-- 1 adet Laptop satıldığını varsayarak stoktan düşüyoruz.
UPDATE Urunler
SET StokMiktari = StokMiktari - 1
WHERE UrunID = 1;

-- SENARYO 3: Hatalı Kayıt Silme
-- Hatalı girilen bir satışı (Örn: SatisID = 1) sistemden siliyoruz.
DELETE FROM Satislar 
WHERE SatisID = 1;

-- Kontrol: Silme ve Güncelleme sonrası son durum
SELECT * FROM Urunler;
SELECT * FROM Satislar;