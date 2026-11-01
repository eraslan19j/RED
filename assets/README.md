# assets/ — Varlık Politikası

Bu milestone'da **dış binary asset kullanılmaz**. Tüm dokular ve modeller
çalışma zamanında deterministik tohumlarla üretilir:

- Dokular: `scripts/utils/texture_factory.gd` (dikişsiz fBm gürültü, biyom
  albedo'ları, normal haritalar, çim kartı, köpük, şelale çizgisi, yükseklik haritası)
- Modeller: `scripts/utils/procedural_mesh.gd` (ağaçlar, kayalar, sütunlar,
  kuleler, şelale kuadları, şimşek çizgileri)

Bu yaklaşım lisans belirsizliğini ortadan kaldırır ve depoyu hafif tutar.
Milestone 2'de lisansları doğrulanmış CC0 kaynaklardan (Poly Haven, ambientCG,
Kenney, OpenGameArt, Godot Asset Library) GLB/PBR entegrasyonu planlanıyor;
böyle bir asset `assets/` altına hangi kaynaktan ve hangi lisansla geldiği
belirtilerek eklenecek.
