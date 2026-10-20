# Copia de recuperación — anterior a la fase de muros invisibles

- Fecha: 2026-10-15 12:30
- Qué contiene: `scripts/`, `verify.sh`, `project.godot`, `export_presets.cfg` y las herramientas de medida de `.tools/recovery` que usan las comprobaciones.
- Por qué: la regla 1 del encargo pide copia de recuperación ANTES de tocar nada.
- Comprobación: `cd .tools/recovery/fase-muros/backup-20261015-1230 && shasum -a 256 -c SHA256SUMS`

## Archivos
    ./.DS_Store
    ./.freebuff/project-id
    ./.godot/.gdignore
    ./.godot/editor/BarcelonaMoto-Tutorial.glb-b6f5df9311113fdafc63bdb2c8ba1da7.scn-folding-eb461691fcaeb3f083bd8a11b2b552bf.cfg
    ./.godot/editor/BarcelonaMoto.glb-3d0749f1b173127721b8fed7d5031933.scn-folding-f7a0c90ad6cb69a7f61dc34b175304b7.cfg
    ./.godot/editor/RedBull-Drive.glb-a0f87076c316669302e4e1e226512561.scn-folding-141dc0c4d1a5db75028c28896483d372.cfg
    ./.godot/editor/RedBull.glb-3ef867285c8401cee1e22aa5cafe59a9.scn-folding-d8c58544a4e12c81e215e79e37839a46.cfg
    ./.godot/editor/editor_layout.cfg
    ./.godot/editor/export-5355e1ae04bc4eefe20e34a285034d7b-RedBull.scn-folding-79a30629d44fe6f2b4dd0b50bdb27e46.cfg
    ./.godot/editor/export-fd33dd40c9aaec1dfc760d0a19f64eef-race.scn-folding-3495a9a3d2015fdb1969cc7af54bf80f.cfg
    ./.godot/editor/filesystem_cache10
    ./.godot/editor/project_metadata.cfg
    ./.godot/editor/race.tscn-folding-fd33dd40c9aaec1dfc760d0a19f64eef.cfg
    ./.godot/editor/script_editor_cache.cfg
    ./.godot/exported/133200997/export-5355e1ae04bc4eefe20e34a285034d7b-RedBull.scn
    ./.godot/exported/133200997/export-fd33dd40c9aaec1dfc760d0a19f64eef-race.scn
    ./.godot/exported/133200997/file_cache
    ./.godot/global_script_class_cache.cfg
    ./.godot/imported/BarcelonaMoto-Tutorial.glb-b6f5df9311113fdafc63bdb2c8ba1da7.md5
    ./.godot/imported/BarcelonaMoto-Tutorial.glb-b6f5df9311113fdafc63bdb2c8ba1da7.scn
    ./.godot/imported/BarcelonaMoto-Tutorial_3dt3B.png-051915f3a03e43f3741f711c04c068f4.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_3dt3B.png-051915f3a03e43f3741f711c04c068f4.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_Barcellona_Box_A.png-4d9fda483ab16dc8506ee3a79d91aed0.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_Barcellona_Box_A.png-4d9fda483ab16dc8506ee3a79d91aed0.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_BricksWall.png-809a5c55c09943b56eb14f3950e70ecb.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_BricksWall.png-809a5c55c09943b56eb14f3950e70ecb.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_BricksWall_MAP.png-f77f87e9d1b81bde25620e49a3515c20.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_BricksWall_MAP.png-f77f87e9d1b81bde25620e49a3515c20.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_BricksWall_NM.png-ef77781d222a38e6e74721faa9d71b8c.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_BricksWall_NM.png-ef77781d222a38e6e74721faa9d71b8c.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_Concrete_wall.png-c1b0235c0eb20db566e1521f5b9291c9.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_Concrete_wall.png-c1b0235c0eb20db566e1521f5b9291c9.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_DRIVER_Face.png-ec3945a49f3821544c50815b42fe3c9b.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_DRIVER_Face.png-ec3945a49f3821544c50815b42fe3c9b.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_DRIVER_Suit.png-df63f8b182e7a30bc1b0044a9e93474b.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_DRIVER_Suit.png-df63f8b182e7a30bc1b0044a9e93474b.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_Garage_Colour.png-80f7128b5f04c75d8529498651dacffe.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_Garage_Colour.png-80f7128b5f04c75d8529498651dacffe.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_GrandStand_base.png-76b981fa62c6df1c3637d1b5fcea0012.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_GrandStand_base.png-76b981fa62c6df1c3637d1b5fcea0012.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_GrandStand_base_MAP.png-c1610d971924c1bcc276f68c1cf0e2f0.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_GrandStand_base_MAP.png-c1610d971924c1bcc276f68c1cf0e2f0.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_GrandStand_base_NMW5.png-3177e20140352a0a1975833be5c484a4.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_GrandStand_base_NMW5.png-3177e20140352a0a1975833be5c484a4.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_Lights_Emissive_DIF.png-305e8f6f9b7923b446021d5a93f11e36.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_Lights_Emissive_DIF.png-305e8f6f9b7923b446021d5a93f11e36.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_Props_PITLANE.png-f1cf347a7bf8ae8766f4f2e94fa7f6f5.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_Props_PITLANE.png-f1cf347a7bf8ae8766f4f2e94fa7f6f5.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_Props_PITLANE_NM.png-b9d45a1234c65419a1e180ce2cd241bd.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_Props_PITLANE_NM.png-b9d45a1234c65419a1e180ce2cd241bd.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_Wood_plank.png-55d6d8a0e023f28018002261d70bd973.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_Wood_plank.png-55d6d8a0e023f28018002261d70bd973.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_Wood_plank_MAP.png-add09879f0db50655be7cf9a63ce4f1e.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_Wood_plank_MAP.png-add09879f0db50655be7cf9a63ce4f1e.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_Wood_plank_NM.png-67980fa4dc1be0b9a4647085bf16125b.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_Wood_plank_NM.png-67980fa4dc1be0b9a4647085bf16125b.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_ac_crew.png-25dbb31af32fce754a04387861eb429d.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_ac_crew.png-25dbb31af32fce754a04387861eb429d.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_ao-ext.png-a31b6905e98aa460890e3e453c7ee490.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_ao-ext.png-a31b6905e98aa460890e3e453c7ee490.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_asd.png-19bee91e4bc5b7b80de09ed157ad32ef.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_asd.png-19bee91e4bc5b7b80de09ed157ad32ef.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_asph-red.png-85fe8ea0c77095f04136b4c624603721.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_asph-red.png-85fe8ea0c77095f04136b4c624603721.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_asph-red_MAP.png-5ec28b5cac93639558c74000cbc23c97.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_asph-red_MAP.png-5ec28b5cac93639558c74000cbc23c97.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_asph-white.png-5249658dba447a22921a78a7308abec0.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_asph-white.png-5249658dba447a22921a78a7308abec0.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_asph_updt.png-22e8cc8062dffd477ed0c3b743443521.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_asph_updt.png-22e8cc8062dffd477ed0c3b743443521.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_background_B.png-8d8305166530b78e83aadd25b121008d.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_background_B.png-8d8305166530b78e83aadd25b121008d.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_barcelona t10.png-b43b6b057f1c31b0cd2952c18a218730.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_barcelona t10.png-b43b6b057f1c31b0cd2952c18a218730.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_bark.png-b8209edb94c2c909e67dc96c0b7a9ba1.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_bark.png-b8209edb94c2c909e67dc96c0b7a9ba1.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_barrier.png-e183914048af168d613c8abbf0b81f6f.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_barrier.png-e183914048af168d613c8abbf0b81f6f.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_box-fence.png-eb04030c0b2334e688c6db8b07857fe0.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_box-fence.png-eb04030c0b2334e688c6db8b07857fe0.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_box-numbers.png-aea6011f1afa8b12b0e2d177fb3315b9.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_box-numbers.png-aea6011f1afa8b12b0e2d177fb3315b9.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_box-wall.png-b6f358d1abf59029a3c3ab2b9472e379.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_box-wall.png-b6f358d1abf59029a3c3ab2b9472e379.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_box-wall_MAP.png-c1d4c2d34cc96ab1933e6e9cda4b6fad.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_box-wall_MAP.png-c1d4c2d34cc96ab1933e6e9cda4b6fad.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_box-wall_NM.png-0ad1440c054af5d1ec95764b0c65e312.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_box-wall_NM.png-0ad1440c054af5d1ec95764b0c65e312.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_box1.png-213e3a6566993b123fbf3fd85ac39d34.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_box1.png-213e3a6566993b123fbf3fd85ac39d34.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_box1_MAP.png-bdec0f496a66cbe83e2cf38114942cf0.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_box1_MAP.png-bdec0f496a66cbe83e2cf38114942cf0.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_box1_NM.png-83da77554484c288999f9dcf63b08d60.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_box1_NM.png-83da77554484c288999f9dcf63b08d60.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_branch5.png-27feafc3f3e021d062f201139b47e5b7.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_branch5.png-27feafc3f3e021d062f201139b47e5b7.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_bridge2.png-94d621fa23dacef16a4c246c57c4869c.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_bridge2.png-94d621fa23dacef16a4c246c57c4869c.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_bridge2_MAP.png-9b4ff9dff419fb086426bbde2fef197b.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_bridge2_MAP.png-9b4ff9dff419fb086426bbde2fef197b.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_bridge2_NM.png-936f89de44c8528deaffbd435f9e5708.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_bridge2_NM.png-936f89de44c8528deaffbd435f9e5708.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_bridge_1B_MAP.png-c011b34f087f9593e587139450524a2e.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_bridge_1B_MAP.png-c011b34f087f9593e587139450524a2e.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_bridge_1_d.png-bef4ad097cffe72e22c23040f1f14638.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_bridge_1_d.png-bef4ad097cffe72e22c23040f1f14638.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_bridge_normal.png-675ee40005ad49980c83b18c185153a7.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_bridge_normal.png-675ee40005ad49980c83b18c185153a7.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_carpet-base_MAP.png-63584b22c75b199c5e45b26296445c34.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_carpet-base_MAP.png-63584b22c75b199c5e45b26296445c34.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_carpet.png-a91ced0832a54d2874f9d8134b44b034.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_carpet.png-a91ced0832a54d2874f9d8134b44b034.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_carpet_NM.png-3df2feae4b18f686ea2907b966220644.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_carpet_NM.png-3df2feae4b18f686ea2907b966220644.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_catalunya spons1.png-b024690682d79b7cf7ac1c524fe67b6d.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_catalunya spons1.png-b024690682d79b7cf7ac1c524fe67b6d.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_clockdisplay.png-8789b6d4c6296aaa1038cc068b944935.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_clockdisplay.png-8789b6d4c6296aaa1038cc068b944935.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_commissario_NEW.png-0c9d6fc7d7124d6a758d92a618c74d2b.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_commissario_NEW.png-0c9d6fc7d7124d6a758d92a618c74d2b.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_concrete_box.png-9c70f231318bfc5c310e9378fe239174.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_concrete_box.png-9c70f231318bfc5c310e9378fe239174.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_concrete_box_MAP.png-1848b590fc91e5b63a641f3425e377c1.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_concrete_box_MAP.png-1848b590fc91e5b63a641f3425e377c1.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_concrete_box_NM.png-38437539368f4d3b8f704668b69cb827.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_concrete_box_NM.png-38437539368f4d3b8f704668b69cb827.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_concrete_white_old_albedo2.png-3376648b96949b3947ef2a9149666738.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_concrete_white_old_albedo2.png-3376648b96949b3947ef2a9149666738.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_curb1_A.png-7b2d877a1cba06e290ff6e7ad9ce95fa.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_curb1_A.png-7b2d877a1cba06e290ff6e7ad9ce95fa.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_curb1_NM.png-3f60c6b01e3f7cdabd887a6e815177ff.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_curb1_NM.png-3f60c6b01e3f7cdabd887a6e815177ff.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_curb2.png-1d84fd446a995966370dcca1b43a47a6.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_curb2.png-1d84fd446a995966370dcca1b43a47a6.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_curb2_NM.png-e966ee61e8d4038206e75eb07876a4bf.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_curb2_NM.png-e966ee61e8d4038206e75eb07876a4bf.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_curb_typeB.png-6fbccc9421d12d8443e8cee4a0522c5a.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_curb_typeB.png-6fbccc9421d12d8443e8cee4a0522c5a.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_curb_typeB_NM.png-21925ba522e4ed403af23f1ddd16f723.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_curb_typeB_NM.png-21925ba522e4ed403af23f1ddd16f723.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_digitalflag.png-381fc452c17618f811c8a1368d9e477d.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_digitalflag.png-381fc452c17618f811c8a1368d9e477d.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_digitalflag_main_alb.png-36a69a06b2693f88b4be9822b75e5c9b.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_digitalflag_main_alb.png-36a69a06b2693f88b4be9822b75e5c9b.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_direction-villa.png-5614f2cdbb95548989c7104cf29a6140.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_direction-villa.png-5614f2cdbb95548989c7104cf29a6140.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_distanz.png-4eeccbf1639f0a50d9dcf93b54e424ab.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_distanz.png-4eeccbf1639f0a50d9dcf93b54e424ab.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_distanz_MAP.png-75a808433f9d43fd64bcb0558665548d.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_distanz_MAP.png-75a808433f9d43fd64bcb0558665548d.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_distanz_NM.png-aaf3c3dc0bccf19591c5d7a825c38287.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_distanz_NM.png-aaf3c3dc0bccf19591c5d7a825c38287.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_drs.png-c41c21369c4181d49741449af404860f.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_drs.png-c41c21369c4181d49741449af404860f.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_fences1.png-1c6d65b88392a75e6e22f7af82abb2fc.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_fences1.png-1c6d65b88392a75e6e22f7af82abb2fc.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_fences2.png-02fc277b1048dcfd54c613b67b80263e.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_fences2.png-02fc277b1048dcfd54c613b67b80263e.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_flat_NM.png-d11c73361fbf4bf06b09e21f38260896.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_flat_NM.png-d11c73361fbf4bf06b09e21f38260896.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_glass-box.png-00ecf0c133d593eab65a540c56142f3b.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_glass-box.png-00ecf0c133d593eab65a540c56142f3b.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_glass-name1.png-1decc12f2c0d78fdfb3c92c74ab3c5f4.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_glass-name1.png-1decc12f2c0d78fdfb3c92c74ab3c5f4.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_grail.png-2777740f8dd344a8e3c787d5e8f75ad7.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_grail.png-2777740f8dd344a8e3c787d5e8f75ad7.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_grail_MAP.png-cf4e83a9b6229f823b7362afa58ee37c.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_grail_MAP.png-cf4e83a9b6229f823b7362afa58ee37c.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_grail_NM.png-ebc0196e68f9db77c9bb1ca1a700f357.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_grail_NM.png-ebc0196e68f9db77c9bb1ca1a700f357.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_grass-brd-ext.png-646403fdb53e6fdc5594f9aa5fa07693.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_grass-brd-ext.png-646403fdb53e6fdc5594f9aa5fa07693.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_grass-brd3-F.png-2e22eedc3c4854731f8f6530ed99c9be.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_grass-brd3-F.png-2e22eedc3c4854731f8f6530ed99c9be.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_grass2_MAP.png-19366445271738512f7b5686e8d1acbd.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_grass2_MAP.png-19366445271738512f7b5686e8d1acbd.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_grass_base2.png-3c4fec7b505edc69af3ecc7a27c404d7.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_grass_base2.png-3c4fec7b505edc69af3ecc7a27c404d7.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_gravel.png-a82c9bda22fd7713ed0f587f942da6c2.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_gravel.png-a82c9bda22fd7713ed0f587f942da6c2.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_grille.png-b2d0753b174d3a2a89091e19620c13a1.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_grille.png-b2d0753b174d3a2a89091e19620c13a1.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_grille2.png-8d72e5a87aca9bd750ea9bcffa848194.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_grille2.png-8d72e5a87aca9bd750ea9bcffa848194.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_grille2_MAP.png-a4edc62fde421e9b3b9a9868899f0f27.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_grille2_MAP.png-a4edc62fde421e9b3b9a9868899f0f27.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_grille2_NM.png-0bf0005265069bfc98fb297d3bc42e0b.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_grille2_NM.png-0bf0005265069bfc98fb297d3bc42e0b.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_grille2_red.png-1a269953021b940f406a175f8983e623.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_grille2_red.png-1a269953021b940f406a175f8983e623.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_grille_MAP.png-08bb0a72e906033c3e2b51fe5cdf3479.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_grille_MAP.png-08bb0a72e906033c3e2b51fe5cdf3479.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_grille_NM.png-3d06e701bca9074275c4a73ab85059fe.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_grille_NM.png-3d06e701bca9074275c4a73ab85059fe.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_groove.png-40fda54b560bbf17c6b887f356d8243c.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_groove.png-40fda54b560bbf17c6b887f356d8243c.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_ground spons 2.png-0e9761b3efdaaaa76cdd20bc6de9c4f0.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_ground spons 2.png-0e9761b3efdaaaa76cdd20bc6de9c4f0.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_gstand-detail2.png-053ebbece94781cc49f1d235c0ac9995.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_gstand-detail2.png-053ebbece94781cc49f1d235c0ac9995.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_gstand-detail3.png-9fd36b2b483365912b53c65b06ce145b.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_gstand-detail3.png-9fd36b2b483365912b53c65b06ce145b.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_gstand-detail3_MAP.png-2871ac73ad9b185d13a396817a4b8d08.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_gstand-detail3_MAP.png-2871ac73ad9b185d13a396817a4b8d08.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_gstand-detail3_NM.png-f0c10ef276eee6405f835616fd243776.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_gstand-detail3_NM.png-f0c10ef276eee6405f835616fd243776.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_itpine_E.png-73c43399979c7e783f9701908848b5da.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_itpine_E.png-73c43399979c7e783f9701908848b5da.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_ivy_hi.png-361f219b8d59e001ea8c80c5463117cf.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_ivy_hi.png-361f219b8d59e001ea8c80c5463117cf.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_lapdisplay.png-9ce5707ca1ecf3297bdae3ef5eb6bfa0.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_lapdisplay.png-9ce5707ca1ecf3297bdae3ef5eb6bfa0.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_ledwall.png-0c0c19daf87303aae015b14af0628c38.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_ledwall.png-0c0c19daf87303aae015b14af0628c38.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_marshall-box.png-595723a1b9b1f7ca63e5944cf549ce99.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_marshall-box.png-595723a1b9b1f7ca63e5944cf549ce99.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_marshall-box_MAP.png-afac36ce3fb6c6c6559421891c73528b.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_marshall-box_MAP.png-afac36ce3fb6c6c6559421891c73528b.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_marshallA.png-852d67ba99d8a78637f1434ae912dd30.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_marshallA.png-852d67ba99d8a78637f1434ae912dd30.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_mid_NM.png-ffad4ff0093f56a9284e54649475932d.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_mid_NM.png-ffad4ff0093f56a9284e54649475932d.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_misc.png-8416f214a40c30d9af84de0869896273.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_misc.png-8416f214a40c30d9af84de0869896273.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_net-alpha.png-852e6a18ca373887f0787979afd1335b.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_net-alpha.png-852e6a18ca373887f0787979afd1335b.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_panels.png-bc5877fbc1ed362d82b4a7acbf7892a5.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_panels.png-bc5877fbc1ed362d82b4a7acbf7892a5.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_paratie1.png-3f2eeebbd799397a66eef35c47a1baa9.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_paratie1.png-3f2eeebbd799397a66eef35c47a1baa9.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_pine_leaf.png-8e403170d8ebbd0aab89105bcdbf66f5.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_pine_leaf.png-8e403170d8ebbd0aab89105bcdbf66f5.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_pitlane-build1.png-1f5cfa2d76b71fd5d440f91c2c5f0dbb.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_pitlane-build1.png-1f5cfa2d76b71fd5d440f91c2c5f0dbb.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_podium.png-ebfb4cabb375255c2906e5d82be051a3.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_podium.png-ebfb4cabb375255c2906e5d82be051a3.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_pole1.png-dcef566666bb5951ba95d222b57493bc.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_pole1.png-dcef566666bb5951ba95d222b57493bc.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_red-pitlane.png-aa90b29f14d6b0a007182860d6f7b157.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_red-pitlane.png-aa90b29f14d6b0a007182860d6f7b157.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_road-concrete-ext.png-076dc45917ebdace334d8735244b310e.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_road-concrete-ext.png-076dc45917ebdace334d8735244b310e.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_roof-tile_D.png-7692b9c4fb8f67d933d41fe8e6ad345d.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_roof-tile_D.png-7692b9c4fb8f67d933d41fe8e6ad345d.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_roof-tile_MAP.png-5f1ff3a08321b4dc1ee55c322c0c819b.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_roof-tile_MAP.png-5f1ff3a08321b4dc1ee55c322c0c819b.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_roof-tile_NM.png-71ef869df65aa561828b4d3a22c8242e.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_roof-tile_NM.png-71ef869df65aa561828b4d3a22c8242e.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_sand_base.png-ac144b8e10376e1f4a02e50b48640474.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_sand_base.png-ac144b8e10376e1f4a02e50b48640474.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_sand_base_MAP.png-ed17596fdbbe95efe1840bdc703f97f5.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_sand_base_MAP.png-ed17596fdbbe95efe1840bdc703f97f5.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_sand_base_NM.png-583df399d2bb986ae0d682f0b083b852.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_sand_base_NM.png-583df399d2bb986ae0d682f0b083b852.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_sat2B.png-4ee1881009c237938d2c0c9c945762c4.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_sat2B.png-4ee1881009c237938d2c0c9c945762c4.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_semaphore.png-a69e46c9232ad91e96389578cec9e6e0.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_semaphore.png-a69e46c9232ad91e96389578cec9e6e0.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_series logo.png-feaf40214f46228f96aba0039c6ef041.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_series logo.png-feaf40214f46228f96aba0039c6ef041.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_slow-curb.png-78fc6c779a0e201fd7368ec94b3120b1.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_slow-curb.png-78fc6c779a0e201fd7368ec94b3120b1.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_slow-curb_MAP.png-45b808b1ff63718cb405df016178aad4.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_slow-curb_MAP.png-45b808b1ff63718cb405df016178aad4.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_slow-curb_NM.png-bf9961874e868c6ac60eea07c043e2ae.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_slow-curb_NM.png-bf9961874e868c6ac60eea07c043e2ae.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_sp_bumps.png-3a7fb50ff9921fde5ac55832074592a0.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_sp_bumps.png-3a7fb50ff9921fde5ac55832074592a0.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_sponsors 2.png-b5de076c18288d006b7f5cad51031256.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_sponsors 2.png-b5de076c18288d006b7f5cad51031256.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_sponsors-ground1.png-f921539f95d8f7b05ed5b8af21ab998f.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_sponsors-ground1.png-f921539f95d8f7b05ed5b8af21ab998f.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_sponsors.png-4c87abd447fff73a0ce43ebc5d557c02.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_sponsors.png-4c87abd447fff73a0ce43ebc5d557c02.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_struc-green-ext.png-e3a64fa44de17c3d6dafa38af67c068d.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_struc-green-ext.png-e3a64fa44de17c3d6dafa38af67c068d.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_structures-alpha.png-655b650c7101bd3e7dcb940b4a3eadd5.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_structures-alpha.png-655b650c7101bd3e7dcb940b4a3eadd5.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_structures-base.png-f402b21b6b082dc037ab2d6d73af9364.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_structures-base.png-f402b21b6b082dc037ab2d6d73af9364.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_structures-base_MAP.png-793f9b241910e04e0acb1b516ba27a5c.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_structures-base_MAP.png-793f9b241910e04e0acb1b516ba27a5c.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_tarmac_green.png-c1d1a38daf0db5d2cb0923e5949ed8a8.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_tarmac_green.png-c1d1a38daf0db5d2cb0923e5949ed8a8.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_tent-fabric1.png-5cfbce37c88df4f36cf5c5e46ad3d55e.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_tent-fabric1.png-5cfbce37c88df4f36cf5c5e46ad3d55e.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_time-tower.png-3f22c8a94ec37ce2043fa16fbe8003c7.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_time-tower.png-3f22c8a94ec37ce2043fa16fbe8003c7.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_tower spons.png-ed0e29f53f4ec8fc25c811bd88b13ef6.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_tower spons.png-ed0e29f53f4ec8fc25c811bd88b13ef6.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_towerdisplay.png-9d5eee1b219b7a3a399c092c3154724c.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_towerdisplay.png-9d5eee1b219b7a3a399c092c3154724c.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_tree_shadow.png-48faeef54ff08ac7ea83d465a245ec99.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_tree_shadow.png-48faeef54ff08ac7ea83d465a245ec99.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_trees2G.png-3735a6388bf14081b4cde11d2ad2d1a9.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_trees2G.png-3735a6388bf14081b4cde11d2ad2d1a9.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_tyres_add2.png-0afaf57941acdc0136cf72d4e09c3659.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_tyres_add2.png-0afaf57941acdc0136cf72d4e09c3659.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_walls1.png-86139feff6d5196e58c32c8fbb19640c.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_walls1.png-86139feff6d5196e58c32c8fbb19640c.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_walls1_MAP.png-21ef489346062e91736a4ca968022d93.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_walls1_MAP.png-21ef489346062e91736a4ca968022d93.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_walls1_NM.png-0421faab4c43af1b40030ac8a2472c7d.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_walls1_NM.png-0421faab4c43af1b40030ac8a2472c7d.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_whiteline.png-17fc3d31e0f6d4cf4d1132a5a52aafc5.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_whiteline.png-17fc3d31e0f6d4cf4d1132a5a52aafc5.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_whiteline3.png-34cf81b5b03afdf677660479bc71637a.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_whiteline3.png-34cf81b5b03afdf677660479bc71637a.md5
    ./.godot/imported/BarcelonaMoto-Tutorial_whiteline4.png-8f1fbf1191fa8f0b09257ecf0174c431.ctex
    ./.godot/imported/BarcelonaMoto-Tutorial_whiteline4.png-8f1fbf1191fa8f0b09257ecf0174c431.md5
    ./.godot/imported/BarcelonaMoto.glb-3d0749f1b173127721b8fed7d5031933.md5
    ./.godot/imported/BarcelonaMoto.glb-3d0749f1b173127721b8fed7d5031933.scn
    ./.godot/imported/BarcelonaMoto_3dt3B.png-21e21c9e1c15e2fd3643521818a481fb.ctex
    ./.godot/imported/BarcelonaMoto_3dt3B.png-21e21c9e1c15e2fd3643521818a481fb.md5
    ./.godot/imported/BarcelonaMoto_Barcellona_Box_A.png-ffcd4a87a4f8e0f789d1bec2918da462.ctex
    ./.godot/imported/BarcelonaMoto_Barcellona_Box_A.png-ffcd4a87a4f8e0f789d1bec2918da462.md5
    ./.godot/imported/BarcelonaMoto_BricksWall.png-ad75bc3723aa083b539b53d818eb66cb.ctex
    ./.godot/imported/BarcelonaMoto_BricksWall.png-ad75bc3723aa083b539b53d818eb66cb.md5
    ./.godot/imported/BarcelonaMoto_BricksWall_MAP_rough4.png-7449f56cf4f3a2798617afbf1c3c26ee.ctex
    ./.godot/imported/BarcelonaMoto_BricksWall_MAP_rough4.png-7449f56cf4f3a2798617afbf1c3c26ee.md5
    ./.godot/imported/BarcelonaMoto_BricksWall_NM.png-4b76b01d3099fcbe206bbf9dedf151a2.ctex
    ./.godot/imported/BarcelonaMoto_BricksWall_NM.png-4b76b01d3099fcbe206bbf9dedf151a2.md5
    ./.godot/imported/BarcelonaMoto_Concrete_wall.png-af23c305aff2380338016bf7eaf7cae3.ctex
    ./.godot/imported/BarcelonaMoto_Concrete_wall.png-af23c305aff2380338016bf7eaf7cae3.md5
    ./.godot/imported/BarcelonaMoto_DRIVER_Face.png-6765a3c1fb88dd546432928785028567.ctex
    ./.godot/imported/BarcelonaMoto_DRIVER_Face.png-6765a3c1fb88dd546432928785028567.md5
    ./.godot/imported/BarcelonaMoto_DRIVER_Suit.png-1d4b7544f55be97be90a14caa28cbdca.ctex
    ./.godot/imported/BarcelonaMoto_DRIVER_Suit.png-1d4b7544f55be97be90a14caa28cbdca.md5
    ./.godot/imported/BarcelonaMoto_Garage_Colour.png-512891e550943fbaf16a5e9ff96b73a1.ctex
    ./.godot/imported/BarcelonaMoto_Garage_Colour.png-512891e550943fbaf16a5e9ff96b73a1.md5
    ./.godot/imported/BarcelonaMoto_GrandStand_base.png-2c04e871344e56a5a24b1ceed9ae3870.ctex
    ./.godot/imported/BarcelonaMoto_GrandStand_base.png-2c04e871344e56a5a24b1ceed9ae3870.md5
    ./.godot/imported/BarcelonaMoto_GrandStand_base_MAP_rough1.png-4d0301844a64160c23289a398b35adb1.ctex
    ./.godot/imported/BarcelonaMoto_GrandStand_base_MAP_rough1.png-4d0301844a64160c23289a398b35adb1.md5
    ./.godot/imported/BarcelonaMoto_GrandStand_base_MAP_rough2.png-6309e480c55ecfcaefdc1ae0dd7af78f.ctex
    ./.godot/imported/BarcelonaMoto_GrandStand_base_MAP_rough2.png-6309e480c55ecfcaefdc1ae0dd7af78f.md5
    ./.godot/imported/BarcelonaMoto_GrandStand_base_MAP_rough44.png-2ff076594f7df7eb4cd497d00ae34904.ctex
    ./.godot/imported/BarcelonaMoto_GrandStand_base_MAP_rough44.png-2ff076594f7df7eb4cd497d00ae34904.md5
    ./.godot/imported/BarcelonaMoto_GrandStand_base_NMW5.png-19804e37a418b176fd2e821eccbb167a.ctex
    ./.godot/imported/BarcelonaMoto_GrandStand_base_NMW5.png-19804e37a418b176fd2e821eccbb167a.md5
    ./.godot/imported/BarcelonaMoto_Lights_Emissive_DIF.png-01d09307d9bd3470135156087e37a9f0.ctex
    ./.godot/imported/BarcelonaMoto_Lights_Emissive_DIF.png-01d09307d9bd3470135156087e37a9f0.md5
    ./.godot/imported/BarcelonaMoto_NULL.png-3cb3b470144c3fd2bf23e18d9b023aee.ctex
    ./.godot/imported/BarcelonaMoto_NULL.png-3cb3b470144c3fd2bf23e18d9b023aee.md5
    ./.godot/imported/BarcelonaMoto_Props_PITLANE.png-c5ce425207a9434900bbc7c85f0401d2.ctex
    ./.godot/imported/BarcelonaMoto_Props_PITLANE.png-c5ce425207a9434900bbc7c85f0401d2.md5
    ./.godot/imported/BarcelonaMoto_Props_PITLANE_NM.png-8ede30bcdc58b7d21e06de1c05862a6c.ctex
    ./.godot/imported/BarcelonaMoto_Props_PITLANE_NM.png-8ede30bcdc58b7d21e06de1c05862a6c.md5
    ./.godot/imported/BarcelonaMoto_Wood_plank.png-aa756866971966ff6468232c45faa9f1.ctex
    ./.godot/imported/BarcelonaMoto_Wood_plank.png-aa756866971966ff6468232c45faa9f1.md5
    ./.godot/imported/BarcelonaMoto_Wood_plank_MAP_rough2.png-ec3955e46a411e49ce2e46a6127c1a40.ctex
    ./.godot/imported/BarcelonaMoto_Wood_plank_MAP_rough2.png-ec3955e46a411e49ce2e46a6127c1a40.md5
    ./.godot/imported/BarcelonaMoto_Wood_plank_NM.png-ac4f5cd50dde3773133b0b714782b673.ctex
    ./.godot/imported/BarcelonaMoto_Wood_plank_NM.png-ac4f5cd50dde3773133b0b714782b673.md5
    ./.godot/imported/BarcelonaMoto_ac_crew.png-5b91c4992eee5f28ed97effd2076f296.ctex
    ./.godot/imported/BarcelonaMoto_ac_crew.png-5b91c4992eee5f28ed97effd2076f296.md5
    ./.godot/imported/BarcelonaMoto_ao-ext.png-bda5e56481bdda2d84949c932760b48c.ctex
    ./.godot/imported/BarcelonaMoto_ao-ext.png-bda5e56481bdda2d84949c932760b48c.md5
    ./.godot/imported/BarcelonaMoto_asd.png-a5fc42e11edb27c55a496b986ee6434d.ctex
    ./.godot/imported/BarcelonaMoto_asd.png-a5fc42e11edb27c55a496b986ee6434d.md5
    ./.godot/imported/BarcelonaMoto_asph-red.png-ec5c109c51dd33b337f69d5294e0039c.ctex
    ./.godot/imported/BarcelonaMoto_asph-red.png-ec5c109c51dd33b337f69d5294e0039c.md5
    ./.godot/imported/BarcelonaMoto_asph-red_MAP_rough1.png-ed2a9ab1c4ff9c0edb08271dd8d0b85b.ctex
    ./.godot/imported/BarcelonaMoto_asph-red_MAP_rough1.png-ed2a9ab1c4ff9c0edb08271dd8d0b85b.md5
    ./.godot/imported/BarcelonaMoto_asph-red_MAP_rough3.png-49cc5758da5459f286282dfa8f269648.ctex
    ./.godot/imported/BarcelonaMoto_asph-red_MAP_rough3.png-49cc5758da5459f286282dfa8f269648.md5
    ./.godot/imported/BarcelonaMoto_asph-white.png-ad3cb2e471bc70bd5dad91fb6bfa225c.ctex
    ./.godot/imported/BarcelonaMoto_asph-white.png-ad3cb2e471bc70bd5dad91fb6bfa225c.md5
    ./.godot/imported/BarcelonaMoto_asph_updt.png-970ce1ef1c8b624b091ccf4446f0854a.ctex
    ./.godot/imported/BarcelonaMoto_asph_updt.png-970ce1ef1c8b624b091ccf4446f0854a.md5
    ./.godot/imported/BarcelonaMoto_background_B.png-f3a1b3f6c28a19df2b2c3961475d30bf.ctex
    ./.godot/imported/BarcelonaMoto_background_B.png-f3a1b3f6c28a19df2b2c3961475d30bf.md5
    ./.godot/imported/BarcelonaMoto_barcelona t10.png-5c027c6691e48dedfd91d325b30c9bc5.ctex
    ./.godot/imported/BarcelonaMoto_barcelona t10.png-5c027c6691e48dedfd91d325b30c9bc5.md5
    ./.godot/imported/BarcelonaMoto_bark.png-72feb94096d243501ea925cf56839f19.ctex
    ./.godot/imported/BarcelonaMoto_bark.png-72feb94096d243501ea925cf56839f19.md5
    ./.godot/imported/BarcelonaMoto_barrier.png-77f0368a0316eb71369cb5c273e4bb26.ctex
    ./.godot/imported/BarcelonaMoto_barrier.png-77f0368a0316eb71369cb5c273e4bb26.md5
    ./.godot/imported/BarcelonaMoto_box-fence.png-cbadda821036f2f7d65e9343ffd6f4be.ctex
    ./.godot/imported/BarcelonaMoto_box-fence.png-cbadda821036f2f7d65e9343ffd6f4be.md5
    ./.godot/imported/BarcelonaMoto_box-numbers.png-7d090ffb6d3dac168191b4a12595643a.ctex
    ./.godot/imported/BarcelonaMoto_box-numbers.png-7d090ffb6d3dac168191b4a12595643a.md5
    ./.godot/imported/BarcelonaMoto_box-wall.png-6ce4a8a0283e98e02bcf2ebd68437e0b.ctex
    ./.godot/imported/BarcelonaMoto_box-wall.png-6ce4a8a0283e98e02bcf2ebd68437e0b.md5
    ./.godot/imported/BarcelonaMoto_box-wall_MAP_rough18.png-4101d1cc7080fc29fc0a0bcdcd97ec8d.ctex
    ./.godot/imported/BarcelonaMoto_box-wall_MAP_rough18.png-4101d1cc7080fc29fc0a0bcdcd97ec8d.md5
    ./.godot/imported/BarcelonaMoto_box-wall_NM.png-6002daca5887f0cc2594b12d3b0927bb.ctex
    ./.godot/imported/BarcelonaMoto_box-wall_NM.png-6002daca5887f0cc2594b12d3b0927bb.md5
    ./.godot/imported/BarcelonaMoto_box1.png-e20bed0c5e3bb53fb0d1c8057db467e9.ctex
    ./.godot/imported/BarcelonaMoto_box1.png-e20bed0c5e3bb53fb0d1c8057db467e9.md5
    ./.godot/imported/BarcelonaMoto_box1_MAP_rough1.png-88c53866ff402e598529ca4eb5afdbcc.ctex
    ./.godot/imported/BarcelonaMoto_box1_MAP_rough1.png-88c53866ff402e598529ca4eb5afdbcc.md5
    ./.godot/imported/BarcelonaMoto_box1_MAP_rough2.png-f7fa2e483c70707a6dd8627d3be96a90.ctex
    ./.godot/imported/BarcelonaMoto_box1_MAP_rough2.png-f7fa2e483c70707a6dd8627d3be96a90.md5
    ./.godot/imported/BarcelonaMoto_box1_MAP_rough20.png-8ec403bb2a16f9e1389aa9d83e95fbd5.ctex
    ./.godot/imported/BarcelonaMoto_box1_MAP_rough20.png-8ec403bb2a16f9e1389aa9d83e95fbd5.md5
    ./.godot/imported/BarcelonaMoto_box1_MAP_rough7.png-2ad8b1c018bb7e2a8848c5713f323141.ctex
    ./.godot/imported/BarcelonaMoto_box1_MAP_rough7.png-2ad8b1c018bb7e2a8848c5713f323141.md5
    ./.godot/imported/BarcelonaMoto_box1_NM.png-f29053fae75ccf902f8e594a7d5e3310.ctex
    ./.godot/imported/BarcelonaMoto_box1_NM.png-f29053fae75ccf902f8e594a7d5e3310.md5
    ./.godot/imported/BarcelonaMoto_branch5.png-c58dc6710fecaa04f668a496ea06f2c9.ctex
    ./.godot/imported/BarcelonaMoto_branch5.png-c58dc6710fecaa04f668a496ea06f2c9.md5
    ./.godot/imported/BarcelonaMoto_bridge2.png-1c9421111da46d8b9dc6958e7576c060.ctex
    ./.godot/imported/BarcelonaMoto_bridge2.png-1c9421111da46d8b9dc6958e7576c060.md5
    ./.godot/imported/BarcelonaMoto_bridge2_MAP_rough5.png-90b6c215fa9d73554ea401932bf870bc.ctex
    ./.godot/imported/BarcelonaMoto_bridge2_MAP_rough5.png-90b6c215fa9d73554ea401932bf870bc.md5
    ./.godot/imported/BarcelonaMoto_bridge2_NM.png-d325843083ebee695247dc1838edd728.ctex
    ./.godot/imported/BarcelonaMoto_bridge2_NM.png-d325843083ebee695247dc1838edd728.md5
    ./.godot/imported/BarcelonaMoto_bridge_1B_MAP_rough1.png-4d0b51614c7ba5beebd0a60c2dd16fcf.ctex
    ./.godot/imported/BarcelonaMoto_bridge_1B_MAP_rough1.png-4d0b51614c7ba5beebd0a60c2dd16fcf.md5
    ./.godot/imported/BarcelonaMoto_bridge_1B_MAP_rough4.png-6ca73d90150ecec6d38df5b1867afbc0.ctex
    ./.godot/imported/BarcelonaMoto_bridge_1B_MAP_rough4.png-6ca73d90150ecec6d38df5b1867afbc0.md5
    ./.godot/imported/BarcelonaMoto_bridge_1_d.png-9b59e79d602ec23fba83977f77a1cd92.ctex
    ./.godot/imported/BarcelonaMoto_bridge_1_d.png-9b59e79d602ec23fba83977f77a1cd92.md5
    ./.godot/imported/BarcelonaMoto_bridge_normal.png-33cdc8382f2113ae92c61b8812d2f611.ctex
    ./.godot/imported/BarcelonaMoto_bridge_normal.png-33cdc8382f2113ae92c61b8812d2f611.md5
    ./.godot/imported/BarcelonaMoto_carpet-base_MAP_rough38.png-cd73ae863c7e6b53c186baa894cd51e4.ctex
    ./.godot/imported/BarcelonaMoto_carpet-base_MAP_rough38.png-cd73ae863c7e6b53c186baa894cd51e4.md5
    ./.godot/imported/BarcelonaMoto_carpet.png-aa2138cd85d590ff4789aac2587f4cf7.ctex
    ./.godot/imported/BarcelonaMoto_carpet.png-aa2138cd85d590ff4789aac2587f4cf7.md5
    ./.godot/imported/BarcelonaMoto_carpet_NM.png-5b09cf8ec1b09e92b3ed5fdc7886c7e0.ctex
    ./.godot/imported/BarcelonaMoto_carpet_NM.png-5b09cf8ec1b09e92b3ed5fdc7886c7e0.md5
    ./.godot/imported/BarcelonaMoto_catalunya spons1.png-e01280998b83d2de70e1aac6186e1e47.ctex
    ./.godot/imported/BarcelonaMoto_catalunya spons1.png-e01280998b83d2de70e1aac6186e1e47.md5
    ./.godot/imported/BarcelonaMoto_clockdisplay.png-f0a131ebb109d91b35fac94a47514cf3.ctex
    ./.godot/imported/BarcelonaMoto_clockdisplay.png-f0a131ebb109d91b35fac94a47514cf3.md5
    ./.godot/imported/BarcelonaMoto_commissario_NEW.png-d940cfc075dcd92d50805e751ec3c502.ctex
    ./.godot/imported/BarcelonaMoto_commissario_NEW.png-d940cfc075dcd92d50805e751ec3c502.md5
    ./.godot/imported/BarcelonaMoto_concrete_box.png-fa6f585d6863e6f6c25568aaf5c023c0.ctex
    ./.godot/imported/BarcelonaMoto_concrete_box.png-fa6f585d6863e6f6c25568aaf5c023c0.md5
    ./.godot/imported/BarcelonaMoto_concrete_box_MAP_rough1.png-00366d9e7cc737a57fecea738ba8e3ec.ctex
    ./.godot/imported/BarcelonaMoto_concrete_box_MAP_rough1.png-00366d9e7cc737a57fecea738ba8e3ec.md5
    ./.godot/imported/BarcelonaMoto_concrete_box_NM.png-ba32884738c419e87759d4b08ea41f40.ctex
    ./.godot/imported/BarcelonaMoto_concrete_box_NM.png-ba32884738c419e87759d4b08ea41f40.md5
    ./.godot/imported/BarcelonaMoto_concrete_white_old_albedo2.png-bb4f06c608151e1f904cfc583e2f48b9.ctex
    ./.godot/imported/BarcelonaMoto_concrete_white_old_albedo2.png-bb4f06c608151e1f904cfc583e2f48b9.md5
    ./.godot/imported/BarcelonaMoto_curb1_A.png-3aa70d27563e292cd79ab41d7c93f934.ctex
    ./.godot/imported/BarcelonaMoto_curb1_A.png-3aa70d27563e292cd79ab41d7c93f934.md5
    ./.godot/imported/BarcelonaMoto_curb1_NM.png-ea5fc82a87e31a6f16f72391297d451a.ctex
    ./.godot/imported/BarcelonaMoto_curb1_NM.png-ea5fc82a87e31a6f16f72391297d451a.md5
    ./.godot/imported/BarcelonaMoto_curb2.png-00bd59c187086bc358f933c5c8fdd86b.ctex
    ./.godot/imported/BarcelonaMoto_curb2.png-00bd59c187086bc358f933c5c8fdd86b.md5
    ./.godot/imported/BarcelonaMoto_curb2_NM.png-9653a134b96c60778d554f894220d166.ctex
    ./.godot/imported/BarcelonaMoto_curb2_NM.png-9653a134b96c60778d554f894220d166.md5
    ./.godot/imported/BarcelonaMoto_curb_typeB.png-034156c797e0504932e331f1af9bf4e2.ctex
    ./.godot/imported/BarcelonaMoto_curb_typeB.png-034156c797e0504932e331f1af9bf4e2.md5
    ./.godot/imported/BarcelonaMoto_curb_typeB_NM.png-0ae74af360f029fd03b082a6adf9f79b.ctex
    ./.godot/imported/BarcelonaMoto_curb_typeB_NM.png-0ae74af360f029fd03b082a6adf9f79b.md5
    ./.godot/imported/BarcelonaMoto_digitalflag.png-6a844b77a2f27b5b9a9951459d406f74.ctex
    ./.godot/imported/BarcelonaMoto_digitalflag.png-6a844b77a2f27b5b9a9951459d406f74.md5
    ./.godot/imported/BarcelonaMoto_digitalflag_main_alb.png-11c59d5931d8ebfadb530a1f93762691.ctex
    ./.godot/imported/BarcelonaMoto_digitalflag_main_alb.png-11c59d5931d8ebfadb530a1f93762691.md5
    ./.godot/imported/BarcelonaMoto_direction-villa.png-6a7508abe82dbed4e0265d8872a37e19.ctex
    ./.godot/imported/BarcelonaMoto_direction-villa.png-6a7508abe82dbed4e0265d8872a37e19.md5
    ./.godot/imported/BarcelonaMoto_distanz.png-96c64ca0425974cd378758e14957b595.ctex
    ./.godot/imported/BarcelonaMoto_distanz.png-96c64ca0425974cd378758e14957b595.md5
    ./.godot/imported/BarcelonaMoto_distanz_MAP_rough1.png-709ba71f1b14327bd5c8830d0e1ec65b.ctex
    ./.godot/imported/BarcelonaMoto_distanz_MAP_rough1.png-709ba71f1b14327bd5c8830d0e1ec65b.md5
    ./.godot/imported/BarcelonaMoto_distanz_NM.png-4b3d705f7e66890204a99bb6ce2676e7.ctex
    ./.godot/imported/BarcelonaMoto_distanz_NM.png-4b3d705f7e66890204a99bb6ce2676e7.md5
    ./.godot/imported/BarcelonaMoto_drs.png-ad9986c3793382717b1521da74a929d0.ctex
    ./.godot/imported/BarcelonaMoto_drs.png-ad9986c3793382717b1521da74a929d0.md5
    ./.godot/imported/BarcelonaMoto_fences1.png-8ff80d9056c5d593f19fa8d75798c9e9.ctex
    ./.godot/imported/BarcelonaMoto_fences1.png-8ff80d9056c5d593f19fa8d75798c9e9.md5
    ./.godot/imported/BarcelonaMoto_fences2.png-bf0dadbed5a27e2db143d9ae80b4f75e.ctex
    ./.godot/imported/BarcelonaMoto_fences2.png-bf0dadbed5a27e2db143d9ae80b4f75e.md5
    ./.godot/imported/BarcelonaMoto_flat_NM.png-2e965f7e5c368212197d9d51a12408eb.ctex
    ./.godot/imported/BarcelonaMoto_flat_NM.png-2e965f7e5c368212197d9d51a12408eb.md5
    ./.godot/imported/BarcelonaMoto_glass-box.png-92ec36ef9952e2211d40612ec7b39426.ctex
    ./.godot/imported/BarcelonaMoto_glass-box.png-92ec36ef9952e2211d40612ec7b39426.md5
    ./.godot/imported/BarcelonaMoto_glass-name1.png-5e9b666b45e8df2ef7a4d645f00c6e34.ctex
    ./.godot/imported/BarcelonaMoto_glass-name1.png-5e9b666b45e8df2ef7a4d645f00c6e34.md5
    ./.godot/imported/BarcelonaMoto_grail.png-33f3bce8da52034d3d0d0988b518b42b.ctex
    ./.godot/imported/BarcelonaMoto_grail.png-33f3bce8da52034d3d0d0988b518b42b.md5
    ./.godot/imported/BarcelonaMoto_grail_MAP_rough60.png-0770465cb929cebbe799f697ee054fb9.ctex
    ./.godot/imported/BarcelonaMoto_grail_MAP_rough60.png-0770465cb929cebbe799f697ee054fb9.md5
    ./.godot/imported/BarcelonaMoto_grail_NM.png-4328c0f5a07c6e1d7427b0ba89adb312.ctex
    ./.godot/imported/BarcelonaMoto_grail_NM.png-4328c0f5a07c6e1d7427b0ba89adb312.md5
    ./.godot/imported/BarcelonaMoto_grass-brd-ext.png-2a4dce1991e8b15f77466c20329d5752.ctex
    ./.godot/imported/BarcelonaMoto_grass-brd-ext.png-2a4dce1991e8b15f77466c20329d5752.md5
    ./.godot/imported/BarcelonaMoto_grass-brd3-F.png-8b790de508dd1796e909fc4aadbe9c54.ctex
    ./.godot/imported/BarcelonaMoto_grass-brd3-F.png-8b790de508dd1796e909fc4aadbe9c54.md5
    ./.godot/imported/BarcelonaMoto_grass2_MAP_rough2.png-e1a72ac124453c1d07754855cab78ad0.ctex
    ./.godot/imported/BarcelonaMoto_grass2_MAP_rough2.png-e1a72ac124453c1d07754855cab78ad0.md5
    ./.godot/imported/BarcelonaMoto_grass_base2.png-e35057e2b4287c3ac6f4143b63b14660.ctex
    ./.godot/imported/BarcelonaMoto_grass_base2.png-e35057e2b4287c3ac6f4143b63b14660.md5
    ./.godot/imported/BarcelonaMoto_gravel.png-83ce180032d67cda39eac9d603af285c.ctex
    ./.godot/imported/BarcelonaMoto_gravel.png-83ce180032d67cda39eac9d603af285c.md5
    ./.godot/imported/BarcelonaMoto_grille.png-93bb07ade5d7c5b87d9756b227177645.ctex
    ./.godot/imported/BarcelonaMoto_grille.png-93bb07ade5d7c5b87d9756b227177645.md5
    ./.godot/imported/BarcelonaMoto_grille2.png-0b01a34b1d51bacb59f7447ed1ad78ad.ctex
    ./.godot/imported/BarcelonaMoto_grille2.png-0b01a34b1d51bacb59f7447ed1ad78ad.md5
    ./.godot/imported/BarcelonaMoto_grille2_MAP_rough8.png-4ab5fc74b0789bdb3b651c6831415dad.ctex
    ./.godot/imported/BarcelonaMoto_grille2_MAP_rough8.png-4ab5fc74b0789bdb3b651c6831415dad.md5
    ./.godot/imported/BarcelonaMoto_grille2_NM.png-489ab08641d7e1f7c7f97b7a5e08ca4a.ctex
    ./.godot/imported/BarcelonaMoto_grille2_NM.png-489ab08641d7e1f7c7f97b7a5e08ca4a.md5
    ./.godot/imported/BarcelonaMoto_grille2_red.png-05ca31bf89bc247befd79509c26a6700.ctex
    ./.godot/imported/BarcelonaMoto_grille2_red.png-05ca31bf89bc247befd79509c26a6700.md5
    ./.godot/imported/BarcelonaMoto_grille_MAP_rough3.png-e96abc70e1679eaea2683bac4b756d91.ctex
    ./.godot/imported/BarcelonaMoto_grille_MAP_rough3.png-e96abc70e1679eaea2683bac4b756d91.md5
    ./.godot/imported/BarcelonaMoto_grille_NM.png-5e88d918956acf9799ad9b3838c371e5.ctex
    ./.godot/imported/BarcelonaMoto_grille_NM.png-5e88d918956acf9799ad9b3838c371e5.md5
    ./.godot/imported/BarcelonaMoto_groove.png-89ffad779f91c266a583f9330dc73736.ctex
    ./.godot/imported/BarcelonaMoto_groove.png-89ffad779f91c266a583f9330dc73736.md5
    ./.godot/imported/BarcelonaMoto_ground spons 2.png-27b574f1509827d59e15c978e4c6fb07.ctex
    ./.godot/imported/BarcelonaMoto_ground spons 2.png-27b574f1509827d59e15c978e4c6fb07.md5
    ./.godot/imported/BarcelonaMoto_gstand-detail2.png-bdfd7d35773c50579154f42e2974dbee.ctex
    ./.godot/imported/BarcelonaMoto_gstand-detail2.png-bdfd7d35773c50579154f42e2974dbee.md5
    ./.godot/imported/BarcelonaMoto_gstand-detail3.png-3ee97774e08ce455dcf89573abbb39d1.ctex
    ./.godot/imported/BarcelonaMoto_gstand-detail3.png-3ee97774e08ce455dcf89573abbb39d1.md5
    ./.godot/imported/BarcelonaMoto_gstand-detail3_MAP_rough3.png-e7564aebeb230054939d0047679943df.ctex
    ./.godot/imported/BarcelonaMoto_gstand-detail3_MAP_rough3.png-e7564aebeb230054939d0047679943df.md5
    ./.godot/imported/BarcelonaMoto_gstand-detail3_NM.png-955c74466da8150727ef1edd62529e2d.ctex
    ./.godot/imported/BarcelonaMoto_gstand-detail3_NM.png-955c74466da8150727ef1edd62529e2d.md5
    ./.godot/imported/BarcelonaMoto_itpine_E.png-132627235a1ccc5a74818fe8781ccb33.ctex
    ./.godot/imported/BarcelonaMoto_itpine_E.png-132627235a1ccc5a74818fe8781ccb33.md5
    ./.godot/imported/BarcelonaMoto_ivy_hi.png-2d2994677d0ea3d7c0ec046bd851b996.ctex
    ./.godot/imported/BarcelonaMoto_ivy_hi.png-2d2994677d0ea3d7c0ec046bd851b996.md5
    ./.godot/imported/BarcelonaMoto_lapdisplay.png-e679b082f523ec5c9ddb37e487b87a97.ctex
    ./.godot/imported/BarcelonaMoto_lapdisplay.png-e679b082f523ec5c9ddb37e487b87a97.md5
    ./.godot/imported/BarcelonaMoto_ledwall.png-ac4c3975d4abe584abcd22aff0ae5120.ctex
    ./.godot/imported/BarcelonaMoto_ledwall.png-ac4c3975d4abe584abcd22aff0ae5120.md5
    ./.godot/imported/BarcelonaMoto_marshall-box.png-3a2c30a095ed52742e78e9e0cddb510c.ctex
    ./.godot/imported/BarcelonaMoto_marshall-box.png-3a2c30a095ed52742e78e9e0cddb510c.md5
    ./.godot/imported/BarcelonaMoto_marshall-box_MAP_rough4.png-41186eb750923ed8d190782aa0eb5559.ctex
    ./.godot/imported/BarcelonaMoto_marshall-box_MAP_rough4.png-41186eb750923ed8d190782aa0eb5559.md5
    ./.godot/imported/BarcelonaMoto_marshallA.png-e41b02043704c221db7c7c3245445654.ctex
    ./.godot/imported/BarcelonaMoto_marshallA.png-e41b02043704c221db7c7c3245445654.md5
    ./.godot/imported/BarcelonaMoto_mid_NM.png-95eb06f0df5408eb920d7ffab0b61cc3.ctex
    ./.godot/imported/BarcelonaMoto_mid_NM.png-95eb06f0df5408eb920d7ffab0b61cc3.md5
    ./.godot/imported/BarcelonaMoto_misc.png-e5678955fdb726bec0e29779108d31d8.ctex
    ./.godot/imported/BarcelonaMoto_misc.png-e5678955fdb726bec0e29779108d31d8.md5
    ./.godot/imported/BarcelonaMoto_net-alpha.png-95f9ba359a5eb27f94673d2418d258d8.ctex
    ./.godot/imported/BarcelonaMoto_net-alpha.png-95f9ba359a5eb27f94673d2418d258d8.md5
    ./.godot/imported/BarcelonaMoto_panels.png-7a4e13749e3bca3f65246bf1a3881699.ctex
    ./.godot/imported/BarcelonaMoto_panels.png-7a4e13749e3bca3f65246bf1a3881699.md5
    ./.godot/imported/BarcelonaMoto_paratie1.png-c6136eee25c645eae79a0ac084985c4e.ctex
    ./.godot/imported/BarcelonaMoto_paratie1.png-c6136eee25c645eae79a0ac084985c4e.md5
    ./.godot/imported/BarcelonaMoto_pine_leaf.png-64d788cf4491271bd2e2cbfa08dcfbeb.ctex
    ./.godot/imported/BarcelonaMoto_pine_leaf.png-64d788cf4491271bd2e2cbfa08dcfbeb.md5
    ./.godot/imported/BarcelonaMoto_pitlane-build1.png-f4e85c056c7375f8d30c2429f9e7abfa.ctex
    ./.godot/imported/BarcelonaMoto_pitlane-build1.png-f4e85c056c7375f8d30c2429f9e7abfa.md5
    ./.godot/imported/BarcelonaMoto_podium.png-9b884b445046582cf3d2c90c4de0e549.ctex
    ./.godot/imported/BarcelonaMoto_podium.png-9b884b445046582cf3d2c90c4de0e549.md5
    ./.godot/imported/BarcelonaMoto_pole1.png-92ed56219d0367a198a14f53fed85ddc.ctex
    ./.godot/imported/BarcelonaMoto_pole1.png-92ed56219d0367a198a14f53fed85ddc.md5
    ./.godot/imported/BarcelonaMoto_red-pitlane.png-21854175bfdc49d57849d2c6f527865d.ctex
    ./.godot/imported/BarcelonaMoto_red-pitlane.png-21854175bfdc49d57849d2c6f527865d.md5
    ./.godot/imported/BarcelonaMoto_road-concrete-ext.png-ee9e163daffe6ad9aa530f1acc469348.ctex
    ./.godot/imported/BarcelonaMoto_road-concrete-ext.png-ee9e163daffe6ad9aa530f1acc469348.md5
    ./.godot/imported/BarcelonaMoto_roof-tile_D.png-8a3f6735c72eaa524aee049559c9c3c3.ctex
    ./.godot/imported/BarcelonaMoto_roof-tile_D.png-8a3f6735c72eaa524aee049559c9c3c3.md5
    ./.godot/imported/BarcelonaMoto_roof-tile_MAP_rough1.png-438fe6d7814df3a8d6b010b7a14fe377.ctex
    ./.godot/imported/BarcelonaMoto_roof-tile_MAP_rough1.png-438fe6d7814df3a8d6b010b7a14fe377.md5
    ./.godot/imported/BarcelonaMoto_roof-tile_NM.png-7ec9b14e8301ddf5d579c13d77834264.ctex
    ./.godot/imported/BarcelonaMoto_roof-tile_NM.png-7ec9b14e8301ddf5d579c13d77834264.md5
    ./.godot/imported/BarcelonaMoto_sand_base.png-1a2e856d764e7a6de0a8947a1205dd5c.ctex
    ./.godot/imported/BarcelonaMoto_sand_base.png-1a2e856d764e7a6de0a8947a1205dd5c.md5
    ./.godot/imported/BarcelonaMoto_sand_base_MAP_rough1.png-c8be0b4cd915e960cc03485b93c97533.ctex
    ./.godot/imported/BarcelonaMoto_sand_base_MAP_rough1.png-c8be0b4cd915e960cc03485b93c97533.md5
    ./.godot/imported/BarcelonaMoto_sand_base_NM.png-21799d5685a3795166029d940d94a32d.ctex
    ./.godot/imported/BarcelonaMoto_sand_base_NM.png-21799d5685a3795166029d940d94a32d.md5
    ./.godot/imported/BarcelonaMoto_sat2B.png-9030cb440ecf39bf76ad7f7e513ca142.ctex
    ./.godot/imported/BarcelonaMoto_sat2B.png-9030cb440ecf39bf76ad7f7e513ca142.md5
    ./.godot/imported/BarcelonaMoto_semaphore.png-10c5e8971b1691cb6e05c3b1704034dc.ctex
    ./.godot/imported/BarcelonaMoto_semaphore.png-10c5e8971b1691cb6e05c3b1704034dc.md5
    ./.godot/imported/BarcelonaMoto_series logo.png-ed5c2918f115b64ad4da2def92129d98.ctex
    ./.godot/imported/BarcelonaMoto_series logo.png-ed5c2918f115b64ad4da2def92129d98.md5
    ./.godot/imported/BarcelonaMoto_slow-curb.png-a689ea5a8c56b9f6b2ca8434263a2941.ctex
    ./.godot/imported/BarcelonaMoto_slow-curb.png-a689ea5a8c56b9f6b2ca8434263a2941.md5
    ./.godot/imported/BarcelonaMoto_slow-curb_MAP_rough2.png-9dbff9fb179b489e5c905ab72bffe328.ctex
    ./.godot/imported/BarcelonaMoto_slow-curb_MAP_rough2.png-9dbff9fb179b489e5c905ab72bffe328.md5
    ./.godot/imported/BarcelonaMoto_slow-curb_NM.png-f10830cb7179379a357c7204b7565c07.ctex
    ./.godot/imported/BarcelonaMoto_slow-curb_NM.png-f10830cb7179379a357c7204b7565c07.md5
    ./.godot/imported/BarcelonaMoto_sp_bumps.png-68695be416574fc51c0c31cbf20fac12.ctex
    ./.godot/imported/BarcelonaMoto_sp_bumps.png-68695be416574fc51c0c31cbf20fac12.md5
    ./.godot/imported/BarcelonaMoto_sponsors 2.png-19139af381c1faf3f6600965cdf4f41c.ctex
    ./.godot/imported/BarcelonaMoto_sponsors 2.png-19139af381c1faf3f6600965cdf4f41c.md5
    ./.godot/imported/BarcelonaMoto_sponsors-ground1.png-e1af85607ae4d7a1cb9fc728e6e8593d.ctex
    ./.godot/imported/BarcelonaMoto_sponsors-ground1.png-e1af85607ae4d7a1cb9fc728e6e8593d.md5
    ./.godot/imported/BarcelonaMoto_sponsors.png-12b2795d49812001ff33d5eeb1156d7c.ctex
    ./.godot/imported/BarcelonaMoto_sponsors.png-12b2795d49812001ff33d5eeb1156d7c.md5
    ./.godot/imported/BarcelonaMoto_struc-green-ext.png-97d1d54c1edf851aaffd5760608762c2.ctex
    ./.godot/imported/BarcelonaMoto_struc-green-ext.png-97d1d54c1edf851aaffd5760608762c2.md5
    ./.godot/imported/BarcelonaMoto_structures-alpha.png-43b7d338f2f13915e693520dddd42ab4.ctex
    ./.godot/imported/BarcelonaMoto_structures-alpha.png-43b7d338f2f13915e693520dddd42ab4.md5
    ./.godot/imported/BarcelonaMoto_structures-base.png-6b42d35c02d9d944efb5b36e7fbf2fb6.ctex
    ./.godot/imported/BarcelonaMoto_structures-base.png-6b42d35c02d9d944efb5b36e7fbf2fb6.md5
    ./.godot/imported/BarcelonaMoto_structures-base_MAP_rough2.png-dc277e26477ffb015bf955659ab36e90.ctex
    ./.godot/imported/BarcelonaMoto_structures-base_MAP_rough2.png-dc277e26477ffb015bf955659ab36e90.md5
    ./.godot/imported/BarcelonaMoto_tarmac_green.png-5d7bb0f37fa373c8fa8fa2ccdffdafd8.ctex
    ./.godot/imported/BarcelonaMoto_tarmac_green.png-5d7bb0f37fa373c8fa8fa2ccdffdafd8.md5
    ./.godot/imported/BarcelonaMoto_tent-fabric1.png-04941982c941bacaee5f0686c3740ae0.ctex
    ./.godot/imported/BarcelonaMoto_tent-fabric1.png-04941982c941bacaee5f0686c3740ae0.md5
    ./.godot/imported/BarcelonaMoto_time-tower.png-4d159210a8944234b72ed7c21f434f01.ctex
    ./.godot/imported/BarcelonaMoto_time-tower.png-4d159210a8944234b72ed7c21f434f01.md5
    ./.godot/imported/BarcelonaMoto_tower spons.png-b038f1539e081845ddad57095830cd9c.ctex
    ./.godot/imported/BarcelonaMoto_tower spons.png-b038f1539e081845ddad57095830cd9c.md5
    ./.godot/imported/BarcelonaMoto_towerdisplay.png-80fe7aee90abaf9e1e0e32aee397ed1b.ctex
    ./.godot/imported/BarcelonaMoto_towerdisplay.png-80fe7aee90abaf9e1e0e32aee397ed1b.md5
    ./.godot/imported/BarcelonaMoto_tree_shadow.png-d9ca9b650037f4f2f468e1aea312977f.ctex
    ./.godot/imported/BarcelonaMoto_tree_shadow.png-d9ca9b650037f4f2f468e1aea312977f.md5
    ./.godot/imported/BarcelonaMoto_trees2G.png-2ef76510adcaadfaff5686ecc4162217.ctex
    ./.godot/imported/BarcelonaMoto_trees2G.png-2ef76510adcaadfaff5686ecc4162217.md5
    ./.godot/imported/BarcelonaMoto_tyres_add2.png-cf64ba1bdb6ba4bc513c5639c35d366e.ctex
    ./.godot/imported/BarcelonaMoto_tyres_add2.png-cf64ba1bdb6ba4bc513c5639c35d366e.md5
    ./.godot/imported/BarcelonaMoto_walls1.png-b032103b78c2ca355911ead595fe0b7a.ctex
    ./.godot/imported/BarcelonaMoto_walls1.png-b032103b78c2ca355911ead595fe0b7a.md5
    ./.godot/imported/BarcelonaMoto_walls1_MAP_rough2.png-461b4367dda8dc62717ba24872546832.ctex
    ./.godot/imported/BarcelonaMoto_walls1_MAP_rough2.png-461b4367dda8dc62717ba24872546832.md5
    ./.godot/imported/BarcelonaMoto_walls1_NM.png-bc8e13f468446a2c22064f20d1335b8c.ctex
    ./.godot/imported/BarcelonaMoto_walls1_NM.png-bc8e13f468446a2c22064f20d1335b8c.md5
    ./.godot/imported/BarcelonaMoto_whiteline.png-e1d6e16c8cedef2ac78940dbc8eeba89.ctex
    ./.godot/imported/BarcelonaMoto_whiteline.png-e1d6e16c8cedef2ac78940dbc8eeba89.md5
    ./.godot/imported/BarcelonaMoto_whiteline3.png-f35d00df9bb318ff8e8a71e6a0b2bee1.ctex
    ./.godot/imported/BarcelonaMoto_whiteline3.png-f35d00df9bb318ff8e8a71e6a0b2bee1.md5
    ./.godot/imported/BarcelonaMoto_whiteline4.png-2615e39df79be1edad98aef8374ddefc.ctex
    ./.godot/imported/BarcelonaMoto_whiteline4.png-2615e39df79be1edad98aef8374ddefc.md5
    ./.godot/imported/RedBull-Drive.glb-a0f87076c316669302e4e1e226512561.md5
    ./.godot/imported/RedBull-Drive.glb-a0f87076c316669302e4e1e226512561.scn
    ./.godot/imported/RedBull-Drive_Image_0.jpg-c70c29ff4fbe904d64d710cade288bf4.ctex
    ./.godot/imported/RedBull-Drive_Image_0.jpg-c70c29ff4fbe904d64d710cade288bf4.md5
    ./.godot/imported/RedBull-Drive_Image_1.jpg-3749919411ccf65c1467b6acec33ba79.ctex
    ./.godot/imported/RedBull-Drive_Image_1.jpg-3749919411ccf65c1467b6acec33ba79.md5
    ./.godot/imported/RedBull-Drive_Image_2.jpg-53e18a5b8cd5ec0f4362b389ee620c52.ctex
    ./.godot/imported/RedBull-Drive_Image_2.jpg-53e18a5b8cd5ec0f4362b389ee620c52.md5
    ./.godot/imported/RedBull-Drive_Image_3.jpg-fb823081a602278afaee45178af89062.ctex
    ./.godot/imported/RedBull-Drive_Image_3.jpg-fb823081a602278afaee45178af89062.md5
    ./.godot/imported/RedBull.glb-3ef867285c8401cee1e22aa5cafe59a9.md5
    ./.godot/imported/RedBull.glb-3ef867285c8401cee1e22aa5cafe59a9.scn
    ./.godot/imported/RedBull_Image_0.jpg-23ecc995d16332a228401992763c176d.ctex
    ./.godot/imported/RedBull_Image_0.jpg-23ecc995d16332a228401992763c176d.md5
    ./.godot/imported/RedBull_Image_1.jpg-9773a7c1e7aa525c8903ea2e05ef5233.ctex
    ./.godot/imported/RedBull_Image_1.jpg-9773a7c1e7aa525c8903ea2e05ef5233.md5
    ./.godot/imported/RedBull_Image_2.jpg-de81708d6ba35ecff91bfc5e6180c4a6.ctex
    ./.godot/imported/RedBull_Image_2.jpg-de81708d6ba35ecff91bfc5e6180c4a6.md5
    ./.godot/imported/RedBull_Image_3.jpg-ab8e6d2435d9b584b9f3f87fdfac0a6d.ctex
    ./.godot/imported/RedBull_Image_3.jpg-ab8e6d2435d9b584b9f3f87fdfac0a6d.md5
    ./.godot/imported/icon.svg-56083ea2a1f1a4f1e49773bdc6d7826c.ctex
    ./.godot/imported/icon.svg-56083ea2a1f1a4f1e49773bdc6d7826c.md5
    ./.godot/scene_groups_cache.cfg
    ./.godot/uid_cache.bin
    ./.tools/ac-gltf-venv/bin/Activate.ps1
    ./.tools/ac-gltf-venv/bin/activate
    ./.tools/ac-gltf-venv/bin/activate.csh
    ./.tools/ac-gltf-venv/bin/activate.fish
    ./.tools/ac-gltf-venv/bin/kn5-studio
    ./.tools/ac-gltf-venv/bin/kn5-survey
    ./.tools/ac-gltf-venv/bin/kn5-to-gltf
    ./.tools/ac-gltf-venv/bin/pip
    ./.tools/ac-gltf-venv/bin/pip3
    ./.tools/ac-gltf-venv/bin/pip3.9
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/.dylibs/libXau.6.dylib
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/.dylibs/libavif.16.3.0.dylib
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/.dylibs/libbrotlicommon.1.1.0.dylib
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/.dylibs/libbrotlidec.1.1.0.dylib
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/.dylibs/libfreetype.6.dylib
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/.dylibs/libharfbuzz.0.dylib
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/.dylibs/libjpeg.62.4.0.dylib
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/.dylibs/liblcms2.2.dylib
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/.dylibs/liblzma.5.dylib
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/.dylibs/libopenjp2.2.5.3.dylib
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/.dylibs/libpng16.16.dylib
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/.dylibs/libsharpyuv.0.dylib
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/.dylibs/libtiff.6.dylib
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/.dylibs/libwebp.7.dylib
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/.dylibs/libwebpdemux.2.dylib
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/.dylibs/libwebpmux.3.dylib
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/.dylibs/libxcb.1.1.0.dylib
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/.dylibs/libz.1.3.1.zlib-ng.dylib
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/AvifImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/BdfFontFile.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/BlpImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/BmpImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/BufrStubImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/ContainerIO.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/CurImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/DcxImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/DdsImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/EpsImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/ExifTags.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/FitsImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/FliImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/FontFile.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/FpxImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/FtexImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/GbrImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/GdImageFile.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/GifImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/GimpGradientFile.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/GimpPaletteFile.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/GribStubImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/Hdf5StubImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/IcnsImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/IcoImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/ImImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/Image.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/ImageChops.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/ImageCms.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/ImageColor.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/ImageDraw.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/ImageDraw2.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/ImageEnhance.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/ImageFile.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/ImageFilter.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/ImageFont.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/ImageGrab.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/ImageMath.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/ImageMode.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/ImageMorph.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/ImageOps.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/ImagePalette.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/ImagePath.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/ImageQt.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/ImageSequence.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/ImageShow.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/ImageStat.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/ImageTk.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/ImageTransform.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/ImageWin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/ImtImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/IptcImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/Jpeg2KImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/JpegImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/JpegPresets.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/McIdasImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/MicImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/MpegImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/MpoImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/MspImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/PSDraw.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/PaletteFile.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/PalmImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/PcdImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/PcfFontFile.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/PcxImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/PdfImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/PdfParser.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/PixarImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/PngImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/PpmImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/PsdImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/QoiImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/SgiImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/SpiderImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/SunImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/TarIO.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/TgaImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/TiffImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/TiffTags.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/WalImageFile.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/WebPImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/WmfImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/XVThumbImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/XbmImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/XpmImagePlugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/__main__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/_avif.cpython-39-darwin.so
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/_avif.pyi
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/_binary.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/_deprecate.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/_imaging.cpython-39-darwin.so
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/_imaging.pyi
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/_imagingcms.cpython-39-darwin.so
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/_imagingcms.pyi
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/_imagingft.cpython-39-darwin.so
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/_imagingft.pyi
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/_imagingmath.cpython-39-darwin.so
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/_imagingmath.pyi
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/_imagingmorph.cpython-39-darwin.so
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/_imagingmorph.pyi
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/_imagingtk.cpython-39-darwin.so
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/_imagingtk.pyi
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/_tkinter_finder.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/_typing.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/_util.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/_version.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/_webp.cpython-39-darwin.so
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/_webp.pyi
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/features.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/py.typed
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/PIL/report.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/__editable__.assetto_corsa_gltf-1.0.0.pth
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/_distutils_hack/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/_distutils_hack/override.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/assetto_corsa_gltf-1.0.0.dist-info/INSTALLER
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/assetto_corsa_gltf-1.0.0.dist-info/METADATA
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/assetto_corsa_gltf-1.0.0.dist-info/RECORD
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/assetto_corsa_gltf-1.0.0.dist-info/REQUESTED
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/assetto_corsa_gltf-1.0.0.dist-info/WHEEL
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/assetto_corsa_gltf-1.0.0.dist-info/direct_url.json
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/assetto_corsa_gltf-1.0.0.dist-info/entry_points.txt
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/assetto_corsa_gltf-1.0.0.dist-info/licenses/LICENSE
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/assetto_corsa_gltf-1.0.0.dist-info/top_level.txt
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/distutils-precedence.pth
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pillow-11.3.0.dist-info/INSTALLER
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pillow-11.3.0.dist-info/METADATA
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pillow-11.3.0.dist-info/RECORD
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pillow-11.3.0.dist-info/REQUESTED
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pillow-11.3.0.dist-info/WHEEL
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pillow-11.3.0.dist-info/licenses/LICENSE
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pillow-11.3.0.dist-info/top_level.txt
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pillow-11.3.0.dist-info/zip-safe
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip-26.0.1.dist-info/INSTALLER
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip-26.0.1.dist-info/METADATA
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip-26.0.1.dist-info/RECORD
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip-26.0.1.dist-info/REQUESTED
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip-26.0.1.dist-info/WHEEL
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip-26.0.1.dist-info/entry_points.txt
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip-26.0.1.dist-info/licenses/AUTHORS.txt
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip-26.0.1.dist-info/licenses/LICENSE.txt
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip-26.0.1.dist-info/licenses/src/pip/_vendor/cachecontrol/LICENSE.txt
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip-26.0.1.dist-info/licenses/src/pip/_vendor/certifi/LICENSE
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip-26.0.1.dist-info/licenses/src/pip/_vendor/dependency_groups/LICENSE.txt
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip-26.0.1.dist-info/licenses/src/pip/_vendor/distlib/LICENSE.txt
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip-26.0.1.dist-info/licenses/src/pip/_vendor/distro/LICENSE
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip-26.0.1.dist-info/licenses/src/pip/_vendor/idna/LICENSE.md
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip-26.0.1.dist-info/licenses/src/pip/_vendor/msgpack/COPYING
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip-26.0.1.dist-info/licenses/src/pip/_vendor/packaging/LICENSE
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip-26.0.1.dist-info/licenses/src/pip/_vendor/packaging/LICENSE.APACHE
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip-26.0.1.dist-info/licenses/src/pip/_vendor/packaging/LICENSE.BSD
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip-26.0.1.dist-info/licenses/src/pip/_vendor/pkg_resources/LICENSE
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip-26.0.1.dist-info/licenses/src/pip/_vendor/platformdirs/LICENSE
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip-26.0.1.dist-info/licenses/src/pip/_vendor/pygments/LICENSE
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip-26.0.1.dist-info/licenses/src/pip/_vendor/pyproject_hooks/LICENSE
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip-26.0.1.dist-info/licenses/src/pip/_vendor/requests/LICENSE
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip-26.0.1.dist-info/licenses/src/pip/_vendor/resolvelib/LICENSE
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip-26.0.1.dist-info/licenses/src/pip/_vendor/rich/LICENSE
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip-26.0.1.dist-info/licenses/src/pip/_vendor/tomli/LICENSE
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip-26.0.1.dist-info/licenses/src/pip/_vendor/tomli_w/LICENSE
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip-26.0.1.dist-info/licenses/src/pip/_vendor/truststore/LICENSE
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip-26.0.1.dist-info/licenses/src/pip/_vendor/urllib3/LICENSE.txt
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/__main__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/__pip-runner__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/build_env.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/cache.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/cli/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/cli/autocompletion.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/cli/base_command.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/cli/cmdoptions.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/cli/command_context.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/cli/index_command.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/cli/main.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/cli/main_parser.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/cli/parser.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/cli/progress_bars.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/cli/req_command.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/cli/spinners.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/cli/status_codes.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/commands/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/commands/cache.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/commands/check.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/commands/completion.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/commands/configuration.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/commands/debug.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/commands/download.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/commands/freeze.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/commands/hash.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/commands/help.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/commands/index.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/commands/inspect.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/commands/install.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/commands/list.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/commands/lock.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/commands/search.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/commands/show.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/commands/uninstall.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/commands/wheel.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/configuration.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/distributions/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/distributions/base.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/distributions/installed.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/distributions/sdist.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/distributions/wheel.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/exceptions.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/index/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/index/collector.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/index/package_finder.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/index/sources.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/locations/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/locations/_distutils.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/locations/_sysconfig.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/locations/base.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/main.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/metadata/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/metadata/_json.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/metadata/base.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/metadata/importlib/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/metadata/importlib/_compat.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/metadata/importlib/_dists.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/metadata/importlib/_envs.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/metadata/pkg_resources.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/models/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/models/candidate.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/models/direct_url.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/models/format_control.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/models/index.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/models/installation_report.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/models/link.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/models/release_control.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/models/scheme.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/models/search_scope.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/models/selection_prefs.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/models/target_python.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/models/wheel.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/network/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/network/auth.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/network/cache.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/network/download.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/network/lazy_wheel.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/network/session.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/network/utils.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/network/xmlrpc.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/operations/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/operations/build/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/operations/build/build_tracker.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/operations/build/metadata.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/operations/build/metadata_editable.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/operations/build/wheel.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/operations/build/wheel_editable.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/operations/check.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/operations/freeze.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/operations/install/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/operations/install/wheel.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/operations/prepare.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/pyproject.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/req/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/req/constructors.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/req/pep723.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/req/req_dependency_group.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/req/req_file.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/req/req_install.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/req/req_set.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/req/req_uninstall.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/resolution/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/resolution/base.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/resolution/legacy/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/resolution/legacy/resolver.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/resolution/resolvelib/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/resolution/resolvelib/base.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/resolution/resolvelib/candidates.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/resolution/resolvelib/factory.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/resolution/resolvelib/found_candidates.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/resolution/resolvelib/provider.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/resolution/resolvelib/reporter.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/resolution/resolvelib/requirements.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/resolution/resolvelib/resolver.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/self_outdated_check.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/utils/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/utils/_jaraco_text.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/utils/_log.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/utils/appdirs.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/utils/compat.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/utils/compatibility_tags.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/utils/datetime.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/utils/deprecation.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/utils/direct_url_helpers.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/utils/egg_link.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/utils/entrypoints.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/utils/filesystem.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/utils/filetypes.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/utils/glibc.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/utils/hashes.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/utils/logging.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/utils/misc.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/utils/packaging.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/utils/pylock.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/utils/retry.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/utils/subprocess.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/utils/temp_dir.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/utils/unpacking.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/utils/urls.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/utils/virtualenv.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/utils/wheel.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/vcs/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/vcs/bazaar.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/vcs/git.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/vcs/mercurial.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/vcs/subversion.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/vcs/versioncontrol.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_internal/wheel_builder.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/README.rst
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/cachecontrol/LICENSE.txt
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/cachecontrol/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/cachecontrol/_cmd.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/cachecontrol/adapter.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/cachecontrol/cache.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/cachecontrol/caches/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/cachecontrol/caches/file_cache.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/cachecontrol/caches/redis_cache.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/cachecontrol/controller.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/cachecontrol/filewrapper.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/cachecontrol/heuristics.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/cachecontrol/py.typed
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/cachecontrol/serialize.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/cachecontrol/wrapper.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/certifi/LICENSE
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/certifi/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/certifi/__main__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/certifi/cacert.pem
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/certifi/core.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/certifi/py.typed
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/dependency_groups/LICENSE.txt
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/dependency_groups/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/dependency_groups/__main__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/dependency_groups/_implementation.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/dependency_groups/_lint_dependency_groups.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/dependency_groups/_pip_wrapper.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/dependency_groups/_toml_compat.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/dependency_groups/py.typed
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/distlib/LICENSE.txt
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/distlib/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/distlib/compat.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/distlib/resources.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/distlib/scripts.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/distlib/t32.exe
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/distlib/t64-arm.exe
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/distlib/t64.exe
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/distlib/util.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/distlib/w32.exe
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/distlib/w64-arm.exe
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/distlib/w64.exe
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/distro/LICENSE
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/distro/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/distro/__main__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/distro/distro.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/distro/py.typed
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/idna/LICENSE.md
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/idna/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/idna/codec.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/idna/compat.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/idna/core.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/idna/idnadata.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/idna/intranges.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/idna/package_data.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/idna/py.typed
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/idna/uts46data.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/msgpack/COPYING
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/msgpack/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/msgpack/exceptions.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/msgpack/ext.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/msgpack/fallback.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/packaging/LICENSE
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/packaging/LICENSE.APACHE
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/packaging/LICENSE.BSD
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/packaging/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/packaging/_elffile.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/packaging/_manylinux.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/packaging/_musllinux.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/packaging/_parser.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/packaging/_structures.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/packaging/_tokenizer.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/packaging/licenses/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/packaging/licenses/_spdx.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/packaging/markers.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/packaging/metadata.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/packaging/py.typed
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/packaging/pylock.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/packaging/requirements.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/packaging/specifiers.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/packaging/tags.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/packaging/utils.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/packaging/version.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/pkg_resources/LICENSE
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/pkg_resources/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/platformdirs/LICENSE
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/platformdirs/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/platformdirs/__main__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/platformdirs/android.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/platformdirs/api.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/platformdirs/macos.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/platformdirs/py.typed
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/platformdirs/unix.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/platformdirs/version.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/platformdirs/windows.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/pygments/LICENSE
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/pygments/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/pygments/__main__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/pygments/console.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/pygments/filter.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/pygments/filters/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/pygments/formatter.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/pygments/formatters/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/pygments/formatters/_mapping.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/pygments/lexer.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/pygments/lexers/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/pygments/lexers/_mapping.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/pygments/lexers/python.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/pygments/modeline.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/pygments/plugin.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/pygments/regexopt.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/pygments/scanner.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/pygments/sphinxext.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/pygments/style.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/pygments/styles/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/pygments/styles/_mapping.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/pygments/token.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/pygments/unistring.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/pygments/util.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/pyproject_hooks/LICENSE
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/pyproject_hooks/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/pyproject_hooks/_impl.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/pyproject_hooks/_in_process/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/pyproject_hooks/_in_process/_in_process.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/pyproject_hooks/py.typed
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/requests/LICENSE
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/requests/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/requests/__version__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/requests/_internal_utils.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/requests/adapters.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/requests/api.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/requests/auth.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/requests/certs.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/requests/compat.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/requests/cookies.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/requests/exceptions.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/requests/help.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/requests/hooks.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/requests/models.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/requests/packages.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/requests/sessions.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/requests/status_codes.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/requests/structures.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/requests/utils.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/resolvelib/LICENSE
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/resolvelib/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/resolvelib/providers.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/resolvelib/py.typed
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/resolvelib/reporters.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/resolvelib/resolvers/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/resolvelib/resolvers/abstract.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/resolvelib/resolvers/criterion.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/resolvelib/resolvers/exceptions.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/resolvelib/resolvers/resolution.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/resolvelib/structs.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/LICENSE
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/__main__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/_cell_widths.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/_emoji_codes.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/_emoji_replace.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/_export_format.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/_extension.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/_fileno.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/_inspect.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/_log_render.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/_loop.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/_null_file.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/_palettes.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/_pick.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/_ratio.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/_spinners.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/_stack.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/_timer.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/_win32_console.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/_windows.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/_windows_renderer.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/_wrap.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/abc.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/align.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/ansi.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/bar.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/box.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/cells.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/color.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/color_triplet.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/columns.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/console.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/constrain.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/containers.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/control.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/default_styles.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/diagnose.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/emoji.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/errors.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/file_proxy.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/filesize.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/highlighter.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/json.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/jupyter.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/layout.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/live.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/live_render.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/logging.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/markup.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/measure.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/padding.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/pager.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/palette.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/panel.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/pretty.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/progress.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/progress_bar.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/prompt.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/protocol.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/py.typed
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/region.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/repr.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/rule.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/scope.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/screen.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/segment.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/spinner.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/status.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/style.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/styled.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/syntax.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/table.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/terminal_theme.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/text.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/theme.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/themes.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/traceback.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/rich/tree.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/tomli/LICENSE
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/tomli/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/tomli/_parser.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/tomli/_re.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/tomli/_types.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/tomli/py.typed
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/tomli_w/LICENSE
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/tomli_w/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/tomli_w/_writer.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/tomli_w/py.typed
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/truststore/LICENSE
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/truststore/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/truststore/_api.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/truststore/_macos.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/truststore/_openssl.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/truststore/_ssl_constants.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/truststore/_windows.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/truststore/py.typed
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/LICENSE.txt
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/_collections.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/_version.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/connection.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/connectionpool.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/contrib/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/contrib/_appengine_environ.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/contrib/_securetransport/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/contrib/_securetransport/bindings.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/contrib/_securetransport/low_level.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/contrib/appengine.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/contrib/ntlmpool.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/contrib/pyopenssl.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/contrib/securetransport.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/contrib/socks.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/exceptions.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/fields.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/filepost.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/packages/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/packages/backports/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/packages/backports/makefile.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/packages/backports/weakref_finalize.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/packages/six.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/poolmanager.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/request.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/response.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/util/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/util/connection.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/util/proxy.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/util/queue.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/util/request.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/util/response.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/util/retry.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/util/ssl_.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/util/ssl_match_hostname.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/util/ssltransport.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/util/timeout.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/util/url.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/urllib3/util/wait.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/_vendor/vendor.txt
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pip/py.typed
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pkg_resources/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pkg_resources/_vendor/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pkg_resources/_vendor/appdirs.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pkg_resources/_vendor/packaging/__about__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pkg_resources/_vendor/packaging/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pkg_resources/_vendor/packaging/_compat.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pkg_resources/_vendor/packaging/_structures.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pkg_resources/_vendor/packaging/_typing.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pkg_resources/_vendor/packaging/markers.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pkg_resources/_vendor/packaging/requirements.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pkg_resources/_vendor/packaging/specifiers.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pkg_resources/_vendor/packaging/tags.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pkg_resources/_vendor/packaging/utils.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pkg_resources/_vendor/packaging/version.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pkg_resources/_vendor/pyparsing.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pkg_resources/extern/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/pkg_resources/tests/data/my-test-package-source/setup.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools-58.0.4.dist-info/INSTALLER
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools-58.0.4.dist-info/LICENSE
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools-58.0.4.dist-info/METADATA
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools-58.0.4.dist-info/RECORD
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools-58.0.4.dist-info/REQUESTED
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools-58.0.4.dist-info/WHEEL
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools-58.0.4.dist-info/entry_points.txt
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools-58.0.4.dist-info/top_level.txt
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_deprecation_warning.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/_msvccompiler.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/archive_util.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/bcppcompiler.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/ccompiler.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/cmd.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/command/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/command/bdist.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/command/bdist_dumb.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/command/bdist_msi.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/command/bdist_rpm.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/command/bdist_wininst.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/command/build.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/command/build_clib.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/command/build_ext.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/command/build_py.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/command/build_scripts.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/command/check.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/command/clean.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/command/config.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/command/install.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/command/install_data.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/command/install_egg_info.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/command/install_headers.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/command/install_lib.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/command/install_scripts.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/command/py37compat.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/command/register.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/command/sdist.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/command/upload.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/config.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/core.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/cygwinccompiler.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/debug.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/dep_util.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/dir_util.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/dist.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/errors.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/extension.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/fancy_getopt.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/file_util.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/filelist.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/log.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/msvc9compiler.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/msvccompiler.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/py35compat.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/py38compat.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/spawn.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/sysconfig.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/text_file.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/unixccompiler.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/util.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/version.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_distutils/versionpredicate.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_imp.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_vendor/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_vendor/more_itertools/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_vendor/more_itertools/more.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_vendor/more_itertools/recipes.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_vendor/ordered_set.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_vendor/packaging/__about__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_vendor/packaging/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_vendor/packaging/_compat.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_vendor/packaging/_structures.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_vendor/packaging/_typing.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_vendor/packaging/markers.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_vendor/packaging/requirements.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_vendor/packaging/specifiers.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_vendor/packaging/tags.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_vendor/packaging/utils.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_vendor/packaging/version.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/_vendor/pyparsing.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/archive_util.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/build_meta.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/cli-32.exe
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/cli-64.exe
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/cli.exe
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/command/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/command/alias.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/command/bdist_egg.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/command/bdist_rpm.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/command/build_clib.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/command/build_ext.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/command/build_py.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/command/develop.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/command/dist_info.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/command/easy_install.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/command/egg_info.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/command/install.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/command/install_egg_info.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/command/install_lib.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/command/install_scripts.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/command/launcher manifest.xml
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/command/py36compat.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/command/register.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/command/rotate.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/command/saveopts.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/command/sdist.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/command/setopt.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/command/test.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/command/upload.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/command/upload_docs.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/config.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/dep_util.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/depends.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/dist.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/errors.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/extension.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/extern/__init__.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/glob.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/gui-32.exe
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/gui-64.exe
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/gui.exe
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/installer.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/launch.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/monkey.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/msvc.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/namespaces.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/package_index.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/py34compat.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/sandbox.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/script (dev).tmpl
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/script.tmpl
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/unicode_utils.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/version.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/wheel.py
    ./.tools/ac-gltf-venv/lib/python3.9/site-packages/setuptools/windows_support.py
    ./.tools/ac-gltf-venv/pyvenv.cfg
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/100.kn5
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/11.kn5
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/4.kn5
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/8.kn5
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/9.kn5
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/ai/fast_lane.ai
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/ai/fast_lane_payloads.bin
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/ai/pit_lane.ai
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/ai/pit_lane_payloads.bin
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/ai/pit_lane_with_grid.ai
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/barcelona_2023_5.kn5
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/barcelona_remastered.fbx
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/barcelona_remastered.fbx - Copy.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/barcelona_remastered.fbx.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/barcelona_remastered.kn5
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/barcelona_remastered_5.fbx
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/barcelona_remastered_5.fbx.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/barcelona_remastered_chicane.fbx
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/barcelona_remastered_chicane.fbx.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/barcelona_remastered_chicane.kn5
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/barcelona_remastered_moto.fbx
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/barcelona_remastered_moto.fbx.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/barcelona_remastered_moto.kn5
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/barcelona_remastered_physics.fbx
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/barcelona_remastered_physics.fbx.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/barcelona_remastered_physics.kn5
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/barcelona_remastered_physics_chicane.fbx
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/barcelona_remastered_physics_chicane.fbx.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/barcelona_remastered_physics_chicane.kn5
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/barcelona_remastered_physics_moto.fbx
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/barcelona_remastered_physics_moto.fbx.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/barcelona_remastered_scoreboard.fbx
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/barcelona_remastered_scoreboard.fbx.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/barcelona_remastered_scoreboard.kn5
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/barcelona_remastered_towerspons.fbx
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/barcelona_remastered_towerspons.fbx.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/data/_surfaces.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/data/audio_sources.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/data/camera_facing.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/data/cameras.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/data/cameras_1.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/data/cameras_2.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/data/cameras_3.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/data/cameras_start.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/data/crew.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/data/drs_zones.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/data/groove.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/data/ideal_line.ai
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/data/lighting.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/data/map.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/data/overlays.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/data/sections.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/data/startinglights.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/data/surfaces.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/extension/clockdisplay - Copy.lua
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/extension/clockdisplay.lua
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/extension/digital_big.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/extension/digital_big.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/extension/dynamic dispalys.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/extension/ext_config.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/extension/lapdisplay.lua
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/extension/scoreboard - Copy.lua
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/extension/scoreboard.lua
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/extension/simplelapdisplay.lua
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/extension/simplelapdisplay2.lua
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/extension/timedisplay.lua
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/map.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/3dt3B.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Asphalt2_1024_A.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Asphalt2_1024_A.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Asphalt2_1024_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Asphalt2_1024_MAP.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Asphalt2_1024_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Asphalt2_1024_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Asphalt4_4096_A.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Asphalt7_4x4_A.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Asphalt7_4x4_NMl.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/BBGRASS_D.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Baloon_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Barcellona_Box_A.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Barcellona_Box_A.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Barcellona_Box_MASK.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Barcellona_Box_MASK.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Barcellona_Box_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Barcellona_Box_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/BoxAO.hdr
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Brick.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Brick_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Brick_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Brick_tile.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/BricksWall.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/BricksWall_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/BricksWall_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Concrete_detail.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Concrete_detail_3.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Concrete_detail_3_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Concrete_detail_4.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Concrete_detail_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Concrete_wall.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/DRIVER_Face.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/DRIVER_Suit.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Decal1.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Decal1.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Garage_Colour.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/GrandStand_base.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/GrandStand_base_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/GrandStand_base_NMW5.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/GrandStand_orig001NormalsMap.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/GrandStand_orig001NormalsMap.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Grass0151_A.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Lights_Emissive_DIF.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Lights_Emissive_DIF.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Lights_Emissive_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Lights_Emissive_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Mask-RED.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/NULL.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Props_PITLANE.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Props_PITLANE_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Roof4.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Roof4.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Roof4_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Roof4_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Rust-detail1.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/SAND-02-500cm_Color-4k.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/TilesSmall.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/TilesSmall_A.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/TilesSmall_A.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/TilesSmall_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/TilesSmall_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Vehicles_D.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Wood_plank.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Wood_plank_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/Wood_plank_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/ac_crew.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/amb.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/amb_map.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/ao-ext.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/ao-ext_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/ao-ext_MAP.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/asd.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/asph-green-b.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/asph-paint-detail.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/asph-paint-detail2.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/asph-paint-detail2_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/asph-paint-detail_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/asph-pitlane-t.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/asph-red.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/asph-red_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/asph-white.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/asph4.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/asph4_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/asph4_MASK.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/asph8_2048.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/asph8_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/asph_updt.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/background_B.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/background_B.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/background_B_emissive.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/background_B_emissive.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/baloon.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/baloon1.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/barcelona t10.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/bark.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/bark_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/bark_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/barrier-b.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/barrier.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/barrier.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/barrier_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/barrier_NM-b.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/barrier_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/barrier_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/barrier_rough.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/barrier_rough.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/barriers-B.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/barriers-B.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/barriers-B_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/barriers-B_MAP.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/barriers-B_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/barriers-B_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/black.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/box-fence.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/box-fence.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/box-fence_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/box-fence_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/box-numbers.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/box-numbers.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/box-wall.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/box-wall.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/box-wall_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/box-wall_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/box-wall_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/box-wall_mask_metallic.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/box-wall_mask_metallic.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/box-wall_wetmask.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/box-wall_wetmask.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/box1.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/box1.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/box1_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/box1_MAP.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/box1_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/box1_emissive.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/box1_emissive.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/box1_mask.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/box1_mask.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/branch5.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/brd.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/bridge2.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/bridge2.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/bridge2_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/bridge2_MAP.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/bridge2_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/bridge_1B_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/bridge_1B_MAP.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/bridge_1B_d.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/bridge_1B_d.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/bridge_1_d.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/bridge_2_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/bridge_2_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/bridge_normal.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/bridge_normal.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/bridges.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/bridges.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/bridges_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/bridges_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/carpet-base.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/carpet-base_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/carpet-base_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/carpet.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/carpet.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/carpet_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/carpet_MAP.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/carpet_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/carpet_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/carpet_height.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/carpet_height.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/carpet_wetmask.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/carpet_wetmask.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/catalunya spons1.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/clockdisplay.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/cloud.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/commissario_NEW.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/concrete_box.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/concrete_box.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/concrete_box_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/concrete_box_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/concrete_green.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/concrete_tile.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/concrete_tile.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/concrete_tile_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/concrete_tile_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/concrete_white_old_albedo2.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/curb1_A.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/curb1_A.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/curb1_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/curb1_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/curb1_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/curb1_albedo.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/curb1_wetmask.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/curb1_wetmask.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/curb2.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/curb2.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/curb2_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/curb2_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/curb2_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/curb2_albedo.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/curb2_wetmask.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/curb2_wetmask.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/curb_typeB.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/curb_typeB.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/curb_typeB_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/curb_typeB_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/curb_typeB_wetmask.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/curb_typeB_wetmask.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/decal2.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/decal2.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/digitalflag.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/digitalflag_main_alb.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/direction-villa.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/direction-villa_Albedo.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/direction-villa_Albedo.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/direction-villa_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/direction-villa_MAP.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/direction-villa_MASK.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/direction-villa_MASK.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/dirt1.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/distanz.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/distanz.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/distanz_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/distanz_MAP.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/distanz_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/distanz_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/drs.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/fences1.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/fences1.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/fences2.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/fences2.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/fences3.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/flat_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/glass-box.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/glass-box.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/glass-box_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/glass-box_MAP.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/glass-name1.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grail.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grail.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grail_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grail_MAP.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grail_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grail_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grass-base2.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grass-brd-ext.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grass-brd-ext.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grass-brd-ext_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grass-brd-ext_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grass-brd3-F.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grass-brd3-F.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grass-brd3-F_MASK.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grass-brd3-F_MASK.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grass2_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grass3Eb.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grass_NM_3_low.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grass_base2.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grass_overlay.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grass_var2.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/gravel.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/gravel.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/gravelExt_mask.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/gravelExt_mask.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/gravel_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/gravel_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/gravel_ext.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/gravel_ext.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/gravel_mask.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/gravel_mask.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grille.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grille.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grille1.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grille1.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grille1_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grille1_MAP.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grille1_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grille1_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grille1_SPEC.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grille1_SPEC.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grille2.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grille2.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grille2_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grille2_MAP.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grille2_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grille2_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grille2_spec.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grille2_spec.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grille_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grille_MAP.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grille_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grille_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grille_Spec.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/grille_Spec.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/groove.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/ground spons 2.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/gstand-detail2.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/gstand-detail2.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/gstand-detail2_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/gstand-detail2_MAP.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/gstand-detail3.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/gstand-detail3.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/gstand-detail3_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/gstand-detail3_MAP.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/gstand-detail3_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/gstand-detail3_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/gstand_base_A.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/gstand_base_A.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/gstand_base_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/gstand_base_MAP.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/gstand_base_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/gstand_base_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/gstand_base_WNM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/gude-2023-06-23.log
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/itpine_E.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/ivy_hi.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/ivy_hi.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/ivy_hi_AO.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/ivy_hi_AO.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/ivy_hi_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/ivy_hi_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/jersey.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/jersey_map.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/jersey_nm.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/lapdisplay.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/ledwall.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/line2.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/marbles.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/marshall-box.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/marshall-box.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/marshall-box_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/marshall-box_MAP.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/marshallA.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/marshallA.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/marshallA_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/marshallA_MAP.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/metal_dt_1.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/metal_plate_1.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/metal_plate_1_A.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/metal_plate_1_A.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/metal_plate_1_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/metal_plate_1_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/metal_plate_roof.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/metal_plate_tile_1.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/mid_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/misc.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/misc.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/misc_map.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/misc_map.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/net-alpha.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/net-alpha.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/panels.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/panels.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/panelsAO.hdr
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/panels_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/panels_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/paratie1.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/paratie1.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/paratie1_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/paratie1_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/pine_leaf.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/pitlane-build1.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/pitlane-build1.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/pitlane-build1_Emissive.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/pitlane-build1_Emissive.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/pitlane-build1_MASK1.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/pitlane-build1_MASK1.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/pitlane-build_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/pitlane-build_MAP.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/pitlane-build_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/pitlane-build_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/podium.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/podium.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/pole1.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/pole1.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/poly2.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/red-pitlane.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/red-pitlane.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/red-pitlane_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/red-pitlane_MAP.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/red-pitlane_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/red-pitlane_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/red.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/rideGreen.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/rideGreen.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/road-concrete-ext.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/road-concrete-ext.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/road-concrete-ext_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/road-concrete-ext_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/road-concrete-ext_mask.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/road-concrete-ext_mask.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/roof-tile_D.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/roof-tile_D.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/roof-tile_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/roof-tile_MAP.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/roof-tile_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/roof-tile_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/rumble-strip-b.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/rumble-strip-b.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/rumble-strip-b_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/rumble-strip-b_MAP.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/rumble-strip-b_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/rumble-strip-b_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/rumble-strip-b_height.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/rumble-strip-b_height.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/rumble-strip-b_wetmask.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/rumble-strip-b_wetmask.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/rumble-strip-c.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/rumble-stripMAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/rumble-stripNM-A.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/sand_base - Copy.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/sand_base.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/sand_base_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/sand_base_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/sand_brd2 - Copy.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/sand_brd2.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/sat2.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/sat2.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/sat2B.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/semaphore.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/series logo.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/slow-curb.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/slow-curb.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/slow-curb_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/slow-curb_MAP.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/slow-curb_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/slow-curb_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/soil_mid_ext3.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/soil_mid_ext4.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/soil_mid_ext4_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/sp_bumps.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/sp_bumps.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/sponsors 2.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/sponsors 2.psd
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/sponsors-ground1.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/sponsors-ground1.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/sponsors.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/sponsors.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/sponsors_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/sponsors_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/sponsors_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/struc-green-ext.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/struc-green-ext.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/struc-green-ext_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/struc-green-ext_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/structures-alpha.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/structures-alpha.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/structures-alpha_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/structures-alpha_MAP.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/structures-base.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/structures-base.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/structures-base_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/stucco_1.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/stucco_1_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/tarmac-detail5.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/tarmac-detail5_NM2.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/tarmac_green.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/tarmac_green.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/tent-fabric1.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/tiles_detail1.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/tiles_detail1.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/tiles_detail2.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/tiles_detail2.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/tiles_detail2_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/tiles_detail2_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/tiles_detail3.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/tiles_detail3.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/tiles_detail3_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/tiles_detail3_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/tiles_detail4.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/tiles_detail4.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/tiles_detail4_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/tiles_detail4_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/time-tower.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/time-tower.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/time-tower_emissive.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/time-tower_emissive.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/time-tower_map.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/time-tower_map.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/tower spons.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/tower spons.psd
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/tower.psd
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/towerdisplay.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/trap_detail.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/trap_detail_NM3.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/tree_shadow.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/trees2G.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/tyres_B.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/tyres_B_NMYB.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/tyres_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/tyres_add1.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/tyres_add2.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/wall_detail.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/wall_detail.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/wall_detail_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/wall_detail_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/walls1.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/walls1.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/walls1_MAP.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/walls1_NM.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/walls1_NM.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/walls1_wetmask.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/walls1_wetmask.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/walls1b.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/white.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/whiteline.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/whiteline3.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/whiteline4.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture/whiteline5.dds
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/tracks - Shortcut.lnk
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023_5.kn5
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_gp_2023/ai/fast_lane.ai
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_gp_2023/ai/fast_lane_payloads.bin
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_gp_2023/ai/pit_lane.ai
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_gp_2023/ai/pit_lane_payloads.bin
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_gp_2023/ai/pit_lane_with_grid.ai
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_gp_2023/data/_surfaces.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_gp_2023/data/audio_sources.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_gp_2023/data/camera_facing.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_gp_2023/data/cameras.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_gp_2023/data/cameras_1.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_gp_2023/data/cameras_2.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_gp_2023/data/cameras_3.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_gp_2023/data/cameras_start.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_gp_2023/data/crew.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_gp_2023/data/drs_zones.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_gp_2023/data/groove.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_gp_2023/data/ideal_line.ai
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_gp_2023/data/lighting.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_gp_2023/data/map.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_gp_2023/data/overlays.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_gp_2023/data/sections.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_gp_2023/data/startinglights.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_gp_2023/data/surfaces.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_gp_2023/extension/clockdisplay.lua
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_gp_2023/extension/digital_big.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_gp_2023/extension/digital_big.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_gp_2023/extension/dynamic dispalys.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_gp_2023/extension/ext_config.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_gp_2023/extension/lapdisplay.lua
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_gp_2023/extension/scoreboard.lua
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_gp_2023/extension/simplelapdisplay.lua
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_gp_2023/extension/simplelapdisplay2.lua
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_gp_2023/extension/timedisplay.lua
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_gp_2023/map.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_remastered.kn5
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_remastered_chicane.kn5
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_remastered_moto.kn5
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_remastered_physics.kn5
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_remastered_physics_chicane.kn5
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_remastered_physics_moto.kn5
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/ext_config.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/Acacia_1.bin
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/Acacia_2.bin
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/Beech_1.bin
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/Beech_2.bin
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/Beech_3.bin
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/Birch_01.bin
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/Birch_02.bin
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/Oak_1.bin
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/Oak_2.bin
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/Palm_1.bin
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/Pine_1.bin
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/Spruce_1.bin
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/maple.bin
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/tree0.zip
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06154420.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06154423.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06154426.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06154430.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06154433.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06154439.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06154442.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06154445.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06154447.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06154453.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06154458.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06154502.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06154559.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06154601.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06154613.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06154625.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06154858.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06154909.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06154916.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06154924.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06154935.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06155008.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06155011.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06155023.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06155047.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06155950.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06155951.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06160000.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06160046.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06160102.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06160110.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06160125.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06160135.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06160140.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06160145.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06160147.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06160151.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06160154.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06160426.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06160436.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06160438.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06160448.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06160453.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06160505.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06160514.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06160531.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06160547.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06160603.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06160627.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06160633.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06160647.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06160716.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06160737.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06160741.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06160755.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06160803.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06160920.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06160934.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06160938.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06160945.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06160948.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06161003.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06161009.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06161022.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06161030.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06161117.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06161124.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06161146.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06161151.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06161158.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06161201.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06161205.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06161207.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06161228.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06161231.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06161247.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06161312.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06161318.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06161345.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06161357.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06161804.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06161809.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06161822.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06161844.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06161857.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06161941.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06162005.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06162011.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06162014.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06162016.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06162018.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06162111.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06162122.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06162138.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06162146.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06162154.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06162159.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06162205.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06162215.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06162219.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06162317.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06162335.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06162401.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06162604.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06162633.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06162706.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06162735.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06162743.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06162805.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06162818.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06162836.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06162918.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06163024.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06163035.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-06163055.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees-27202343.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/extension/trees/trees.txt
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/models_barcelona_2023.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/models_barcelona_gp_2023.ini
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/ui/barcelona_2023/outline.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/ui/barcelona_2023/outline_cropped.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/ui/barcelona_2023/preview.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/ui/barcelona_2023/ui_track.json
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/ui/barcelona_gp_2023/outline.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/ui/barcelona_gp_2023/outline_cropped.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/ui/barcelona_gp_2023/preview.png
    ./.tools/ac-source/Barcelona 3.1/fn_barcelona/ui/barcelona_gp_2023/ui_track.json
    ./.tools/android-export-attempt.log
    ./.tools/android-export-final.log
    ./.tools/android-export-scoped.log
    ./.tools/assetto-corsa-gltf/.flake8
    ./.tools/assetto-corsa-gltf/.git/HEAD
    ./.tools/assetto-corsa-gltf/.git/config
    ./.tools/assetto-corsa-gltf/.git/description
    ./.tools/assetto-corsa-gltf/.git/hooks/applypatch-msg.sample
    ./.tools/assetto-corsa-gltf/.git/hooks/commit-msg.sample
    ./.tools/assetto-corsa-gltf/.git/hooks/fsmonitor-watchman.sample
    ./.tools/assetto-corsa-gltf/.git/hooks/post-update.sample
    ./.tools/assetto-corsa-gltf/.git/hooks/pre-applypatch.sample
    ./.tools/assetto-corsa-gltf/.git/hooks/pre-commit.sample
    ./.tools/assetto-corsa-gltf/.git/hooks/pre-merge-commit.sample
    ./.tools/assetto-corsa-gltf/.git/hooks/pre-push.sample
    ./.tools/assetto-corsa-gltf/.git/hooks/pre-rebase.sample
    ./.tools/assetto-corsa-gltf/.git/hooks/pre-receive.sample
    ./.tools/assetto-corsa-gltf/.git/hooks/prepare-commit-msg.sample
    ./.tools/assetto-corsa-gltf/.git/hooks/push-to-checkout.sample
    ./.tools/assetto-corsa-gltf/.git/hooks/sendemail-validate.sample
    ./.tools/assetto-corsa-gltf/.git/hooks/update.sample
    ./.tools/assetto-corsa-gltf/.git/index
    ./.tools/assetto-corsa-gltf/.git/info/exclude
    ./.tools/assetto-corsa-gltf/.git/logs/HEAD
    ./.tools/assetto-corsa-gltf/.git/logs/refs/heads/main
    ./.tools/assetto-corsa-gltf/.git/logs/refs/remotes/origin/HEAD
    ./.tools/assetto-corsa-gltf/.git/objects/pack/pack-5f4ea923663b8efc8db871ff53e1003d167dd14b.idx
    ./.tools/assetto-corsa-gltf/.git/objects/pack/pack-5f4ea923663b8efc8db871ff53e1003d167dd14b.pack
    ./.tools/assetto-corsa-gltf/.git/objects/pack/pack-5f4ea923663b8efc8db871ff53e1003d167dd14b.rev
    ./.tools/assetto-corsa-gltf/.git/packed-refs
    ./.tools/assetto-corsa-gltf/.git/refs/heads/main
    ./.tools/assetto-corsa-gltf/.git/refs/remotes/origin/HEAD
    ./.tools/assetto-corsa-gltf/.git/shallow
    ./.tools/assetto-corsa-gltf/.gitattributes
    ./.tools/assetto-corsa-gltf/.github/workflows/ci.yml
    ./.tools/assetto-corsa-gltf/.github/workflows/pages.yml
    ./.tools/assetto-corsa-gltf/.gitignore
    ./.tools/assetto-corsa-gltf/CHANGELOG.md
    ./.tools/assetto-corsa-gltf/CONTRIBUTING.md
    ./.tools/assetto-corsa-gltf/LICENSE
    ./.tools/assetto-corsa-gltf/README.md
    ./.tools/assetto-corsa-gltf/assets/kn5-studio.png
    ./.tools/assetto-corsa-gltf/assets/og.png
    ./.tools/assetto-corsa-gltf/docs/cars.md
    ./.tools/assetto-corsa-gltf/docs/cli.md
    ./.tools/assetto-corsa-gltf/docs/development.md
    ./.tools/assetto-corsa-gltf/docs/faq.md
    ./.tools/assetto-corsa-gltf/docs/index.md
    ./.tools/assetto-corsa-gltf/docs/installation.md
    ./.tools/assetto-corsa-gltf/docs/limitations.md
    ./.tools/assetto-corsa-gltf/docs/output.md
    ./.tools/assetto-corsa-gltf/docs/preview.md
    ./.tools/assetto-corsa-gltf/docs/quick-start.md
    ./.tools/assetto-corsa-gltf/docs/supported-files.md
    ./.tools/assetto-corsa-gltf/docs/tracks.md
    ./.tools/assetto-corsa-gltf/docs/troubleshooting.md
    ./.tools/assetto-corsa-gltf/docs/workflow.md
    ./.tools/assetto-corsa-gltf/examples/README.md
    ./.tools/assetto-corsa-gltf/examples/batch_convert.py
    ./.tools/assetto-corsa-gltf/examples/read_hierarchy.py
    ./.tools/assetto-corsa-gltf/examples/viewer.html
    ./.tools/assetto-corsa-gltf/pyproject.toml
    ./.tools/assetto-corsa-gltf/scripts/build_site.py
    ./.tools/assetto-corsa-gltf/scripts/make_og.py
    ./.tools/assetto-corsa-gltf/scripts/static/favicon.svg
    ./.tools/assetto-corsa-gltf/scripts/static/fonts/inter-latin.woff2
    ./.tools/assetto-corsa-gltf/scripts/static/search.js
    ./.tools/assetto-corsa-gltf/scripts/static/site.js
    ./.tools/assetto-corsa-gltf/scripts/static/style.css
    ./.tools/assetto-corsa-gltf/scripts/templates/home.html
    ./.tools/assetto-corsa-gltf/scripts/templates/page.html
    ./.tools/assetto-corsa-gltf/src/acgltf/__init__.py
    ./.tools/assetto-corsa-gltf/src/acgltf/convert.py
    ./.tools/assetto-corsa-gltf/src/acgltf/kn5.py
    ./.tools/assetto-corsa-gltf/src/acgltf/studio.py
    ./.tools/assetto-corsa-gltf/src/acgltf/survey.py
    ./.tools/assetto-corsa-gltf/src/acgltf/viewer/index.html
    ./.tools/assetto-corsa-gltf/src/acgltf/viewer/three/LICENSE
    ./.tools/assetto-corsa-gltf/src/acgltf/viewer/three/build/three.module.min.js
    ./.tools/assetto-corsa-gltf/src/acgltf/viewer/three/examples/jsm/controls/OrbitControls.js
    ./.tools/assetto-corsa-gltf/src/acgltf/viewer/three/examples/jsm/loaders/GLTFLoader.js
    ./.tools/assetto-corsa-gltf/src/acgltf/viewer/three/examples/jsm/utils/BufferGeometryUtils.js
    ./.tools/assetto-corsa-gltf/src/assetto_corsa_gltf.egg-info/PKG-INFO
    ./.tools/assetto-corsa-gltf/src/assetto_corsa_gltf.egg-info/SOURCES.txt
    ./.tools/assetto-corsa-gltf/src/assetto_corsa_gltf.egg-info/dependency_links.txt
    ./.tools/assetto-corsa-gltf/src/assetto_corsa_gltf.egg-info/entry_points.txt
    ./.tools/assetto-corsa-gltf/src/assetto_corsa_gltf.egg-info/requires.txt
    ./.tools/assetto-corsa-gltf/src/assetto_corsa_gltf.egg-info/top_level.txt
    ./.tools/assetto-corsa-gltf/tests/test_convert.py
    ./.tools/assetto-corsa-gltf/tests/test_lod.py
    ./.tools/assetto-corsa-gltf/tests/test_paint.py
    ./.tools/assetto-corsa-gltf/tests/test_search.js
    ./.tools/assetto-corsa-gltf/tests/test_site.py
    ./.tools/assetto-corsa-gltf/tests/test_studio.py
    ./.tools/dynamics-diag.log
    ./.tools/dynamics-diag2.log
    ./.tools/dynamics-probe-final.log
    ./.tools/dynamics-probe-final2.log
    ./.tools/dynamics-probe.log
    ./.tools/dynamics-probe2.log
    ./.tools/dynamics-probe3.log
    ./.tools/dynamics-probe4.log
    ./.tools/dynamics-probe5.log
    ./.tools/dynamics-probe6.log
    ./.tools/f1-android-after.png
    ./.tools/f1-android-later.png
    ./.tools/f1-android-preview.html
    ./.tools/f1-android-preview.png
    ./.tools/f1-android-start.png
    ./.tools/geom_audit.py
    ./.tools/gltf-loader-probe.log
    ./.tools/godot-editor.log
    ./.tools/godot-import.log
    ./.tools/godot-import2.log
    ./.tools/godot-import3.log
    ./.tools/godot-lint.log
    ./.tools/godot/Godot.app/Contents/CodeResources
    ./.tools/godot/Godot.app/Contents/Info.plist
    ./.tools/godot/Godot.app/Contents/MacOS/Godot
    ./.tools/godot/Godot.app/Contents/PkgInfo
    ./.tools/godot/Godot.app/Contents/Resources/Assets.car
    ./.tools/godot/Godot.app/Contents/Resources/GDScript.icns
    ./.tools/godot/Godot.app/Contents/Resources/GodotLG.icns
    ./.tools/godot/Godot.app/Contents/Resources/Project.icns
    ./.tools/godot/Godot.app/Contents/Resources/Resource.icns
    ./.tools/godot/Godot.app/Contents/Resources/Scene.icns
    ./.tools/godot/Godot.app/Contents/Resources/Shader.icns
    ./.tools/godot/Godot.app/Contents/Resources/af.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/ar.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/az.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/bg.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/bn.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/br.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/ca.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/cs.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/da.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/de.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/el.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/en.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/eo.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/es.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/es_AR.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/et.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/eu.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/fa.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/fi.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/fil.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/fr.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/ga.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/gl.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/he.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/hi.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/hr.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/hu.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/id.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/is.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/it.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/ja.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/ka.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/km.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/ko.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/lt.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/lv.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/mi.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/mk.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/ml.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/mr.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/ms.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/nb.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/nl.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/or.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/pl.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/pt.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/pt_BR.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/ro.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/ru.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/si.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/sk.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/sl.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/sq.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/sr-Cyrl.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/sr-Latn.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/sv.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/ta.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/te.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/th.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/tr.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/tt.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/tzm.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/uk.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/ur_PK.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/vi.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/zh_CN.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/zh_HK.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/Resources/zh_TW.lproj/InfoPlist.strings
    ./.tools/godot/Godot.app/Contents/_CodeSignature/CodeResources
    ./.tools/godot/godot.zip
    ./.tools/io_import_accsv/.git/HEAD
    ./.tools/io_import_accsv/.git/config
    ./.tools/io_import_accsv/.git/description
    ./.tools/io_import_accsv/.git/hooks/applypatch-msg.sample
    ./.tools/io_import_accsv/.git/hooks/commit-msg.sample
    ./.tools/io_import_accsv/.git/hooks/fsmonitor-watchman.sample
    ./.tools/io_import_accsv/.git/hooks/post-update.sample
    ./.tools/io_import_accsv/.git/hooks/pre-applypatch.sample
    ./.tools/io_import_accsv/.git/hooks/pre-commit.sample
    ./.tools/io_import_accsv/.git/hooks/pre-merge-commit.sample
    ./.tools/io_import_accsv/.git/hooks/pre-push.sample
    ./.tools/io_import_accsv/.git/hooks/pre-rebase.sample
    ./.tools/io_import_accsv/.git/hooks/pre-receive.sample
    ./.tools/io_import_accsv/.git/hooks/prepare-commit-msg.sample
    ./.tools/io_import_accsv/.git/hooks/push-to-checkout.sample
    ./.tools/io_import_accsv/.git/hooks/sendemail-validate.sample
    ./.tools/io_import_accsv/.git/hooks/update.sample
    ./.tools/io_import_accsv/.git/index
    ./.tools/io_import_accsv/.git/info/exclude
    ./.tools/io_import_accsv/.git/logs/HEAD
    ./.tools/io_import_accsv/.git/logs/refs/heads/master
    ./.tools/io_import_accsv/.git/logs/refs/remotes/origin/HEAD
    ./.tools/io_import_accsv/.git/objects/pack/pack-dc47aadf7987f5a1b846192fe3e331993d20b204.idx
    ./.tools/io_import_accsv/.git/objects/pack/pack-dc47aadf7987f5a1b846192fe3e331993d20b204.pack
    ./.tools/io_import_accsv/.git/objects/pack/pack-dc47aadf7987f5a1b846192fe3e331993d20b204.rev
    ./.tools/io_import_accsv/.git/packed-refs
    ./.tools/io_import_accsv/.git/refs/heads/master
    ./.tools/io_import_accsv/.git/refs/remotes/origin/HEAD
    ./.tools/io_import_accsv/.git/refs/tags/2.8
    ./.tools/io_import_accsv/.git/shallow
    ./.tools/io_import_accsv/README.md
    ./.tools/io_import_accsv/__init__.py
    ./.tools/io_import_accsv/export_ai.py
    ./.tools/io_import_accsv/export_csv.py
    ./.tools/io_import_accsv/export_ini.py
    ./.tools/io_import_accsv/export_kn5.py
    ./.tools/io_import_accsv/import_ai.py
    ./.tools/io_import_accsv/import_csv.py
    ./.tools/io_import_accsv/import_ini.py
    ./.tools/io_import_accsv/import_kn5.py
    ./.tools/io_import_accsv/kn5/exporter_utils.py
    ./.tools/io_import_accsv/kn5/kn5_writer.py
    ./.tools/io_import_accsv/kn5/material_writer.py
    ./.tools/io_import_accsv/kn5/node_writer.py
    ./.tools/io_import_accsv/kn5/texture_writer.py
    ./.tools/io_import_accsv/kn52fbx/AcTools.dll
    ./.tools/io_import_accsv/kn52fbx/FbxConverter.exe
    ./.tools/io_import_accsv/kn52fbx/kn52fbx.exe
    ./.tools/kn5subset/100.kn5
    ./.tools/kn5subset/4.kn5
    ./.tools/kn5subset/8.kn5
    ./.tools/kn5subset/9.kn5
    ./.tools/kn5subset/barcelona_2023_5.kn5
    ./.tools/kn5subset/barcelona_remastered.kn5
    ./.tools/kn5subset/barcelona_remastered_moto.kn5
    ./.tools/kn5subset/barcelona_remastered_physics.kn5
    ./.tools/kn5subset/barcelona_remastered_physics_moto.kn5
    ./.tools/kn5subset/conversion.log
    ./.tools/kn5subset/test-moto.glb
    ./.tools/kn5subset/track-selected.glb
    ./.tools/kn5subset/track-selected.surfaces.json
    ./.tools/lap-probe.log
    ./.tools/lap-probe2.log
    ./.tools/layout_check.py
    ./.tools/optimize_glb.py
    ./.tools/recovery/AndroidTouch.java
    ./.tools/recovery/AndroidTouchOfftrack.java
    ./.tools/recovery/android-accelerating.png
    ./.tools/recovery/android-braking.png
    ./.tools/recovery/android-export-steering.log
    ./.tools/recovery/android-final.png
    ./.tools/recovery/android-multitouch.png
    ./.tools/recovery/android-start.png
    ./.tools/recovery/android-touch-offtrack.jar
    ./.tools/recovery/android-touch.jar
    ./.tools/recovery/apk-acelerando-car.png
    ./.tools/recovery/apk-acelerando-hud.png
    ./.tools/recovery/apk-acelerando-landscape.png
    ./.tools/recovery/apk-acelerando.png
    ./.tools/recovery/apk-definitivo-5556.png
    ./.tools/recovery/apk-definitivo-landscape.png
    ./.tools/recovery/apk-definitivo.png
    ./.tools/recovery/apk-final-start.png
    ./.tools/recovery/apk-frenando-car.png
    ./.tools/recovery/apk-frenando-hud.png
    ./.tools/recovery/apk-frenando-landscape.png
    ./.tools/recovery/apk-frenando.png
    ./.tools/recovery/apk-hashes-steering.txt
    ./.tools/recovery/apk-signature-steering.log
    ./.tools/recovery/artifact_audit.json
    ./.tools/recovery/audit_blender_geometry.py
    ./.tools/recovery/audit_delivery.py
    ./.tools/recovery/audit_materials.py
    ./.tools/recovery/audit_track_materials.py
    ./.tools/recovery/audit_wheels_mesh.py
    ./.tools/recovery/avd/F1Recovery.avd/AVD.conf
    ./.tools/recovery/avd/F1Recovery.avd/bootcompleted.ini
    ./.tools/recovery/avd/F1Recovery.avd/cache.img
    ./.tools/recovery/avd/F1Recovery.avd/cache.img.qcow2
    ./.tools/recovery/avd/F1Recovery.avd/config.ini
    ./.tools/recovery/avd/F1Recovery.avd/emu-launch-params.txt
    ./.tools/recovery/avd/F1Recovery.avd/emulator-user.ini
    ./.tools/recovery/avd/F1Recovery.avd/encryptionkey.img
    ./.tools/recovery/avd/F1Recovery.avd/encryptionkey.img.qcow2
    ./.tools/recovery/avd/F1Recovery.avd/hardware-qemu.ini
    ./.tools/recovery/avd/F1Recovery.avd/hardware-qemu.ini.lock
    ./.tools/recovery/avd/F1Recovery.avd/initrd
    ./.tools/recovery/avd/F1Recovery.avd/modem_simulator/etc/modem_simulator/files/numeric_operator.xml
    ./.tools/recovery/avd/F1Recovery.avd/modem_simulator/iccprofile_for_carrierapitests.xml
    ./.tools/recovery/avd/F1Recovery.avd/modem_simulator/iccprofile_for_sim0.xml
    ./.tools/recovery/avd/F1Recovery.avd/modem_simulator/iccprofile_for_sim_tel_alaska.xml
    ./.tools/recovery/avd/F1Recovery.avd/modem_simulator/modem_nvram.json
    ./.tools/recovery/avd/F1Recovery.avd/multiinstance.lock
    ./.tools/recovery/avd/F1Recovery.avd/netsim.ini
    ./.tools/recovery/avd/F1Recovery.avd/qemu-version.txt
    ./.tools/recovery/avd/F1Recovery.avd/read-snapshot.txt
    ./.tools/recovery/avd/F1Recovery.avd/userdata-qemu.img
    ./.tools/recovery/avd/F1Recovery.avd/userdata-qemu.img.qcow2
    ./.tools/recovery/avd/F1Recovery.avd/version_num.cache
    ./.tools/recovery/avd/F1Recovery.ini
    ./.tools/recovery/bake_roughness_maps.py
    ./.tools/recovery/barrier-impact-1.log
    ./.tools/recovery/barrier-impact-2.log
    ./.tools/recovery/bateria-final.log
    ./.tools/recovery/camera_pixels.py
    ./.tools/recovery/car_report.json
    ./.tools/recovery/check_display.py
    ./.tools/recovery/check_hashes.py
    ./.tools/recovery/check_logcat.py
    ./.tools/recovery/check_packaged.py
    ./.tools/recovery/controls-probe-steering.log
    ./.tools/recovery/controls-retest.log
    ./.tools/recovery/conversion_report.json
    ./.tools/recovery/crop-car-road.png
    ./.tools/recovery/dex-offtrack/classes.dex
    ./.tools/recovery/dex/classes.dex
    ./.tools/recovery/driving-probe-steering.log
    ./.tools/recovery/dynamics-probe-steering.log
    ./.tools/recovery/dynamics-retest.log
    ./.tools/recovery/emu-shot-1.png
    ./.tools/recovery/export_car.py
    ./.tools/recovery/fase-camara/INFORME-FASE-CAMARA.md
    ./.tools/recovery/fase-camara/antes/capturas/100-coche.png
    ./.tools/recovery/fase-camara/antes/capturas/100-fondo.png
    ./.tools/recovery/fase-camara/antes/capturas/107-coche.png
    ./.tools/recovery/fase-camara/antes/capturas/107-fondo.png
    ./.tools/recovery/fase-camara/antes/capturas/150-coche.png
    ./.tools/recovery/fase-camara/antes/capturas/150-fondo.png
    ./.tools/recovery/fase-camara/antes/capturas/191-coche.png
    ./.tools/recovery/fase-camara/antes/capturas/191-fondo.png
    ./.tools/recovery/fase-camara/antes/capturas/200-coche.png
    ./.tools/recovery/fase-camara/antes/capturas/200-fondo.png
    ./.tools/recovery/fase-camara/antes/capturas/50-coche.png
    ./.tools/recovery/fase-camara/antes/capturas/50-fondo.png
    ./.tools/recovery/fase-camara/antes/capturas/frenada-100-coche.png
    ./.tools/recovery/fase-camara/antes/capturas/frenada-100-fondo.png
    ./.tools/recovery/fase-camara/antes/capturas/frenada-150-coche.png
    ./.tools/recovery/fase-camara/antes/capturas/frenada-150-fondo.png
    ./.tools/recovery/fase-camara/antes/capturas/frenada-50-coche.png
    ./.tools/recovery/fase-camara/antes/capturas/frenada-50-fondo.png
    ./.tools/recovery/fase-camara/antes/capturas/frenado-final-coche.png
    ./.tools/recovery/fase-camara/antes/capturas/frenado-final-fondo.png
    ./.tools/recovery/fase-camara/antes/capturas/parado-coche.png
    ./.tools/recovery/fase-camara/antes/capturas/parado-fondo.png
    ./.tools/recovery/fase-camara/antes/medidas.json
    ./.tools/recovery/fase-camara/antes/pixeles.json
    ./.tools/recovery/fase-camara/antes/probe.log
    ./.tools/recovery/fase-camara/captura-dispositivo-abortada.log
    ./.tools/recovery/fase-camara/captura-dispositivo.log
    ./.tools/recovery/fase-camara/capturar_dispositivo.py
    ./.tools/recovery/fase-camara/capturas/100-coche.png
    ./.tools/recovery/fase-camara/capturas/100-fondo.png
    ./.tools/recovery/fase-camara/capturas/107-coche.png
    ./.tools/recovery/fase-camara/capturas/107-fondo.png
    ./.tools/recovery/fase-camara/capturas/150-coche.png
    ./.tools/recovery/fase-camara/capturas/150-fondo.png
    ./.tools/recovery/fase-camara/capturas/191-coche.png
    ./.tools/recovery/fase-camara/capturas/191-fondo.png
    ./.tools/recovery/fase-camara/capturas/200-coche.png
    ./.tools/recovery/fase-camara/capturas/200-fondo.png
    ./.tools/recovery/fase-camara/capturas/50-coche.png
    ./.tools/recovery/fase-camara/capturas/50-fondo.png
    ./.tools/recovery/fase-camara/capturas/frenada-100-coche.png
    ./.tools/recovery/fase-camara/capturas/frenada-100-fondo.png
    ./.tools/recovery/fase-camara/capturas/frenada-150-coche.png
    ./.tools/recovery/fase-camara/capturas/frenada-150-fondo.png
    ./.tools/recovery/fase-camara/capturas/frenada-50-coche.png
    ./.tools/recovery/fase-camara/capturas/frenada-50-fondo.png
    ./.tools/recovery/fase-camara/capturas/frenado-final-coche.png
    ./.tools/recovery/fase-camara/capturas/frenado-final-fondo.png
    ./.tools/recovery/fase-camara/capturas/muro-0-coche.png
    ./.tools/recovery/fase-camara/capturas/muro-0-fondo.png
    ./.tools/recovery/fase-camara/capturas/muro-1-coche.png
    ./.tools/recovery/fase-camara/capturas/muro-1-fondo.png
    ./.tools/recovery/fase-camara/capturas/muro-2-coche.png
    ./.tools/recovery/fase-camara/capturas/muro-2-fondo.png
    ./.tools/recovery/fase-camara/capturas/muro-prueba-coche.png
    ./.tools/recovery/fase-camara/capturas/muro-prueba-fondo.png
    ./.tools/recovery/fase-camara/capturas/parado-coche.png
    ./.tools/recovery/fase-camara/capturas/parado-fondo.png
    ./.tools/recovery/fase-camara/capturas/pixeles-dispositivo.json
    ./.tools/recovery/fase-camara/comparativa.html
    ./.tools/recovery/fase-camara/dispositivo-primera-corrida/captura-dispositivo.log
    ./.tools/recovery/fase-camara/dispositivo-primera-corrida/capturas.json
    ./.tools/recovery/fase-camara/dispositivo-primera-corrida/disp-001.png
    ./.tools/recovery/fase-camara/dispositivo-primera-corrida/disp-002.png
    ./.tools/recovery/fase-camara/dispositivo-primera-corrida/disp-003.png
    ./.tools/recovery/fase-camara/dispositivo-primera-corrida/disp-004.png
    ./.tools/recovery/fase-camara/dispositivo-primera-corrida/disp-005.png
    ./.tools/recovery/fase-camara/dispositivo-primera-corrida/disp-006.png
    ./.tools/recovery/fase-camara/dispositivo-primera-corrida/disp-007.png
    ./.tools/recovery/fase-camara/dispositivo-primera-corrida/disp-008.png
    ./.tools/recovery/fase-camara/dispositivo-primera-corrida/disp-009.png
    ./.tools/recovery/fase-camara/dispositivo-primera-corrida/disp-010.png
    ./.tools/recovery/fase-camara/dispositivo-primera-corrida/disp-011.png
    ./.tools/recovery/fase-camara/dispositivo-primera-corrida/disp-012.png
    ./.tools/recovery/fase-camara/dispositivo-primera-corrida/disp-013.png
    ./.tools/recovery/fase-camara/dispositivo-primera-corrida/pixeles-dispositivo.json
    ./.tools/recovery/fase-camara/emulador.log
    ./.tools/recovery/fase-camara/galeria.py
    ./.tools/recovery/fase-camara/medidas.json
    ./.tools/recovery/fase-camara/pixeles.json
    ./.tools/recovery/fase-camara/probe.log
    ./.tools/recovery/fase-camara/verify.log
    ./.tools/recovery/fase-fp/INFORME-FASE-FP.md
    ./.tools/recovery/fase-fp/barrido/combo-00-z-0.18-y+0.20-fov74-pitch17.png
    ./.tools/recovery/fase-fp/barrido/combo-01-z+0.45-y+0.24-fov74-pitch12.png
    ./.tools/recovery/fase-fp/barrido/combo-02-z+0.55-y+0.24-fov60-pitch10.png
    ./.tools/recovery/fase-fp/barrido/combo-03-z+0.55-y+0.24-fov50-pitch08.png
    ./.tools/recovery/fase-fp/barrido/combo-04-z+0.55-y+0.30-fov50-pitch10.png
    ./.tools/recovery/fase-fp/barrido/combo-05-z+0.65-y+0.26-fov55-pitch09.png
    ./.tools/recovery/fase-fp/barrido/combo-06-z+0.40-y+0.22-fov45-pitch07.png
    ./.tools/recovery/fase-fp/barrido/combo-07-z+0.30-y+0.18-fov40-pitch06.png
    ./.tools/recovery/fase-fp/barrido/hoja.html
    ./.tools/recovery/fase-fp/barrido/zoom.html
    ./.tools/recovery/fase-fp/barrido_morro.gd
    ./.tools/recovery/fase-fp/capturar_morro_dispositivo.py
    ./.tools/recovery/fase-fp/capturas/cambio-morro-00.png
    ./.tools/recovery/fase-fp/capturas/cambio-morro-01.png
    ./.tools/recovery/fase-fp/capturas/cambio-morro-02.png
    ./.tools/recovery/fase-fp/capturas/cambio-morro-03.png
    ./.tools/recovery/fase-fp/capturas/cambio-morro-04.png
    ./.tools/recovery/fase-fp/capturas/cambio-morro-05.png
    ./.tools/recovery/fase-fp/capturas/cambio-morro-06.png
    ./.tools/recovery/fase-fp/capturas/cambio-morro-07.png
    ./.tools/recovery/fase-fp/capturas/cambio-morro-08.png
    ./.tools/recovery/fase-fp/capturas/cambio-morro-09.png
    ./.tools/recovery/fase-fp/capturas/cambio-morro-10.png
    ./.tools/recovery/fase-fp/capturas/cambio-morro-11.png
    ./.tools/recovery/fase-fp/capturas/cambio-morro-12.png
    ./.tools/recovery/fase-fp/capturas/cambio-morro-13.png
    ./.tools/recovery/fase-fp/capturas/cambio-morro-14.png
    ./.tools/recovery/fase-fp/capturas/cambio-morro-15.png
    ./.tools/recovery/fase-fp/capturas/cambio-morro-16.png
    ./.tools/recovery/fase-fp/capturas/cambio-persecucion-00.png
    ./.tools/recovery/fase-fp/capturas/cambio-persecucion-01.png
    ./.tools/recovery/fase-fp/capturas/cambio-persecucion-02.png
    ./.tools/recovery/fase-fp/capturas/cambio-persecucion-03.png
    ./.tools/recovery/fase-fp/capturas/cambio-persecucion-04.png
    ./.tools/recovery/fase-fp/capturas/cambio-persecucion-05.png
    ./.tools/recovery/fase-fp/capturas/cambio-persecucion-06.png
    ./.tools/recovery/fase-fp/capturas/cambio-persecucion-07.png
    ./.tools/recovery/fase-fp/capturas/cambio-persecucion-08.png
    ./.tools/recovery/fase-fp/capturas/cambio-persecucion-09.png
    ./.tools/recovery/fase-fp/capturas/cambio-persecucion-10.png
    ./.tools/recovery/fase-fp/capturas/cambio-persecucion-11.png
    ./.tools/recovery/fase-fp/capturas/cambio-persecucion-12.png
    ./.tools/recovery/fase-fp/capturas/cambio-persecucion-13.png
    ./.tools/recovery/fase-fp/capturas/cambio-persecucion-14.png
    ./.tools/recovery/fase-fp/capturas/cambio-persecucion-15.png
    ./.tools/recovery/fase-fp/capturas/cambio-persecucion-16.png
    ./.tools/recovery/fase-fp/capturas/composicion-100-coche-magenta.png
    ./.tools/recovery/fase-fp/capturas/composicion-100-delanteras-cian.png
    ./.tools/recovery/fase-fp/capturas/composicion-100-sin-coche.png
    ./.tools/recovery/fase-fp/capturas/composicion-100-sin-delanteras.png
    ./.tools/recovery/fase-fp/capturas/composicion-100-todo.png
    ./.tools/recovery/fase-fp/capturas/composicion-150-coche-magenta.png
    ./.tools/recovery/fase-fp/capturas/composicion-150-delanteras-cian.png
    ./.tools/recovery/fase-fp/capturas/composicion-150-sin-coche.png
    ./.tools/recovery/fase-fp/capturas/composicion-150-sin-delanteras.png
    ./.tools/recovery/fase-fp/capturas/composicion-150-todo.png
    ./.tools/recovery/fase-fp/capturas/composicion-200-coche-magenta.png
    ./.tools/recovery/fase-fp/capturas/composicion-200-delanteras-cian.png
    ./.tools/recovery/fase-fp/capturas/composicion-200-sin-coche.png
    ./.tools/recovery/fase-fp/capturas/composicion-200-sin-delanteras.png
    ./.tools/recovery/fase-fp/capturas/composicion-200-todo.png
    ./.tools/recovery/fase-fp/capturas/composicion-curva-coche-magenta.png
    ./.tools/recovery/fase-fp/capturas/composicion-curva-delanteras-cian.png
    ./.tools/recovery/fase-fp/capturas/composicion-curva-sin-coche.png
    ./.tools/recovery/fase-fp/capturas/composicion-curva-sin-delanteras.png
    ./.tools/recovery/fase-fp/capturas/composicion-curva-todo.png
    ./.tools/recovery/fase-fp/capturas/composicion-frenada-coche-magenta.png
    ./.tools/recovery/fase-fp/capturas/composicion-frenada-delanteras-cian.png
    ./.tools/recovery/fase-fp/capturas/composicion-frenada-sin-coche.png
    ./.tools/recovery/fase-fp/capturas/composicion-frenada-sin-delanteras.png
    ./.tools/recovery/fase-fp/capturas/composicion-frenada-todo.png
    ./.tools/recovery/fase-fp/capturas/composicion-parado-coche-magenta.png
    ./.tools/recovery/fase-fp/capturas/composicion-parado-delanteras-cian.png
    ./.tools/recovery/fase-fp/capturas/composicion-parado-sin-coche.png
    ./.tools/recovery/fase-fp/capturas/composicion-parado-sin-delanteras.png
    ./.tools/recovery/fase-fp/capturas/composicion-parado-todo.png
    ./.tools/recovery/fase-fp/capturas/morro-100.png
    ./.tools/recovery/fase-fp/capturas/morro-150.png
    ./.tools/recovery/fase-fp/capturas/morro-200.png
    ./.tools/recovery/fase-fp/capturas/morro-curva.png
    ./.tools/recovery/fase-fp/capturas/morro-frenada.png
    ./.tools/recovery/fase-fp/capturas/morro-parado.png
    ./.tools/recovery/fase-fp/entrega.json
    ./.tools/recovery/fase-fp/galeria.html
    ./.tools/recovery/fase-fp/geometria_modelo.gd
    ./.tools/recovery/fase-fp/hoja-de-contacto.html
    ./.tools/recovery/fase-fp/hoja_de_contacto.py
    ./.tools/recovery/fase-fp/logs/barrido.log
    ./.tools/recovery/fase-fp/logs/compilar-morro.log
    ./.tools/recovery/fase-fp/logs/geometria-modelo.log
    ./.tools/recovery/fase-fp/logs/morro-probe.log
    ./.tools/recovery/fase-fp/logs/verify-morro.log
    ./.tools/recovery/fase-fp/morro-pixeles.json
    ./.tools/recovery/fase-fp/morro.json
    ./.tools/recovery/fase-fp/morro_pixeles.py
    ./.tools/recovery/fase-fp/referencia.png
    ./.tools/recovery/fase-muros/backup-20261015-1230/MANIFEST.md
    ./.tools/recovery/fase-muros/backup-20261015-1230/SHA256SUMS
    ./.tools/recovery/fase-muros/backup-20261015-1230/camera_pixels.py
    ./.tools/recovery/fase-muros/backup-20261015-1230/export_presets.cfg
    ./.tools/recovery/fase-muros/backup-20261015-1230/project.godot
    ./.tools/recovery/fase-muros/backup-20261015-1230/screen_check.py
    ./.tools/recovery/fase-muros/backup-20261015-1230/screen_geometry.py
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/api_probe.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/api_probe.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/barrier_impact_probe.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/barrier_impact_probe.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/camera_nose_probe.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/camera_nose_probe.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/camera_probe.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/camera_probe.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/car_controller.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/car_controller.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/car_delivery_probe.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/car_delivery_probe.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/car_parts_probe.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/car_parts_probe.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/car_wheel_probe.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/car_wheel_probe.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/collision_inventory_probe.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/collision_inventory_probe.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/controls_probe.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/controls_probe.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/direct_dyn_probe.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/direct_dyn_probe.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/drive_diag_probe.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/drive_diag_probe.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/driving_probe.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/driving_probe.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/dynamics_probe.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/dynamics_probe.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/force_probe.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/force_probe.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/fps_probe.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/fps_probe.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/gltf_model.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/gltf_model.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/headless_layout_check.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/headless_layout_check.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/lap_probe.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/lap_probe.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/line_curvature_probe.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/line_curvature_probe.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/loader_probe.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/loader_probe.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/offtrack_drive_probe.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/offtrack_drive_probe.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/offtrack_mobility_probe.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/offtrack_mobility_probe.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/offtrack_scan_probe.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/offtrack_scan_probe.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/pbr_probe.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/pbr_probe.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/race.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/race.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/race_hud.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/race_hud.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/render_probe.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/render_probe.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/runtime_probe.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/runtime_probe.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/steer_sign_probe.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/steer_sign_probe.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/steering_probe.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/steering_probe.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/surface_grip_probe.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/surface_grip_probe.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/suspension_probe.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/suspension_probe.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/touch_controls.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/touch_controls.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/track_data.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/track_data.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/track_probe.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/track_probe.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/vehicle_normalize.py
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/wall_visibility_probe.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/wall_visibility_probe.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/wheel_diag_probe.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/wheel_diag_probe.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/wheel_suspension.gd
    ./.tools/recovery/fase-muros/backup-20261015-1230/scripts/wheel_suspension.gd.uid
    ./.tools/recovery/fase-muros/backup-20261015-1230/verify.sh
    ./.tools/recovery/fase-ruedas/INFORME-FASE-RUEDAS.md
    ./.tools/recovery/fase-ruedas/comparar.py
    ./.tools/recovery/fase-ruedas/comparativa.html
    ./.tools/recovery/fase-ruedas/comparativa/aceleracion-camara_del_juego.png
    ./.tools/recovery/fase-ruedas/comparativa/aceleracion-frontal.png
    ./.tools/recovery/fase-ruedas/comparativa/aceleracion-lateral.png
    ./.tools/recovery/fase-ruedas/comparativa/aceleracion-rueda_delantera_der.png
    ./.tools/recovery/fase-ruedas/comparativa/aceleracion-rueda_delantera_izq.png
    ./.tools/recovery/fase-ruedas/comparativa/aceleracion-rueda_trasera_izq.png
    ./.tools/recovery/fase-ruedas/comparativa/aceleracion-trasera_baja.png
    ./.tools/recovery/fase-ruedas/comparativa/curva_moderada-camara_del_juego.png
    ./.tools/recovery/fase-ruedas/comparativa/curva_moderada-frontal.png
    ./.tools/recovery/fase-ruedas/comparativa/curva_moderada-lateral.png
    ./.tools/recovery/fase-ruedas/comparativa/curva_moderada-rueda_delantera_der.png
    ./.tools/recovery/fase-ruedas/comparativa/curva_moderada-rueda_delantera_izq.png
    ./.tools/recovery/fase-ruedas/comparativa/curva_moderada-rueda_trasera_izq.png
    ./.tools/recovery/fase-ruedas/comparativa/curva_moderada-trasera_baja.png
    ./.tools/recovery/fase-ruedas/comparativa/curva_rapida-camara_del_juego.png
    ./.tools/recovery/fase-ruedas/comparativa/curva_rapida-frontal.png
    ./.tools/recovery/fase-ruedas/comparativa/curva_rapida-lateral.png
    ./.tools/recovery/fase-ruedas/comparativa/curva_rapida-rueda_delantera_der.png
    ./.tools/recovery/fase-ruedas/comparativa/curva_rapida-rueda_delantera_izq.png
    ./.tools/recovery/fase-ruedas/comparativa/curva_rapida-rueda_trasera_izq.png
    ./.tools/recovery/fase-ruedas/comparativa/curva_rapida-trasera_baja.png
    ./.tools/recovery/fase-ruedas/comparativa/frenada-camara_del_juego.png
    ./.tools/recovery/fase-ruedas/comparativa/frenada-frontal.png
    ./.tools/recovery/fase-ruedas/comparativa/frenada-lateral.png
    ./.tools/recovery/fase-ruedas/comparativa/frenada-rueda_delantera_der.png
    ./.tools/recovery/fase-ruedas/comparativa/frenada-rueda_delantera_izq.png
    ./.tools/recovery/fase-ruedas/comparativa/frenada-rueda_trasera_izq.png
    ./.tools/recovery/fase-ruedas/comparativa/frenada-trasera_baja.png
    ./.tools/recovery/fase-ruedas/comparativa/reposo-camara_del_juego.png
    ./.tools/recovery/fase-ruedas/comparativa/reposo-frontal.png
    ./.tools/recovery/fase-ruedas/comparativa/reposo-lateral.png
    ./.tools/recovery/fase-ruedas/comparativa/reposo-rueda_delantera_der.png
    ./.tools/recovery/fase-ruedas/comparativa/reposo-rueda_delantera_izq.png
    ./.tools/recovery/fase-ruedas/comparativa/reposo-rueda_trasera_izq.png
    ./.tools/recovery/fase-ruedas/comparativa/reposo-trasera_baja.png
    ./.tools/recovery/fase-ruedas/comparativa/resalto-camara_del_juego.png
    ./.tools/recovery/fase-ruedas/comparativa/resalto-frontal.png
    ./.tools/recovery/fase-ruedas/comparativa/resalto-lateral.png
    ./.tools/recovery/fase-ruedas/comparativa/resalto-rueda_delantera_der.png
    ./.tools/recovery/fase-ruedas/comparativa/resalto-rueda_delantera_izq.png
    ./.tools/recovery/fase-ruedas/comparativa/resalto-rueda_trasera_izq.png
    ./.tools/recovery/fase-ruedas/comparativa/resalto-trasera_baja.png
    ./.tools/recovery/fase-ruedas/logs/audit_entrega.log
    ./.tools/recovery/fase-ruedas/logs/comparativa.log
    ./.tools/recovery/fase-ruedas/logs/emulador.log
    ./.tools/recovery/fase-ruedas/logs/emulador.pid
    ./.tools/recovery/fase-ruedas/logs/sonda_ruedas.log
    ./.tools/recovery/fase-ruedas/logs/sonda_suspension.log
    ./.tools/recovery/fase-ruedas/logs/verify.log
    ./.tools/recovery/fase-ruedas/vistas/antes/aceleracion-camara_del_juego.png
    ./.tools/recovery/fase-ruedas/vistas/antes/aceleracion-frontal.png
    ./.tools/recovery/fase-ruedas/vistas/antes/aceleracion-lateral.png
    ./.tools/recovery/fase-ruedas/vistas/antes/aceleracion-rueda_delantera_der.png
    ./.tools/recovery/fase-ruedas/vistas/antes/aceleracion-rueda_delantera_izq.png
    ./.tools/recovery/fase-ruedas/vistas/antes/aceleracion-rueda_trasera_izq.png
    ./.tools/recovery/fase-ruedas/vistas/antes/aceleracion-trasera_baja.png
    ./.tools/recovery/fase-ruedas/vistas/antes/curva_moderada-camara_del_juego.png
    ./.tools/recovery/fase-ruedas/vistas/antes/curva_moderada-frontal.png
    ./.tools/recovery/fase-ruedas/vistas/antes/curva_moderada-lateral.png
    ./.tools/recovery/fase-ruedas/vistas/antes/curva_moderada-rueda_delantera_der.png
    ./.tools/recovery/fase-ruedas/vistas/antes/curva_moderada-rueda_delantera_izq.png
    ./.tools/recovery/fase-ruedas/vistas/antes/curva_moderada-rueda_trasera_izq.png
    ./.tools/recovery/fase-ruedas/vistas/antes/curva_moderada-trasera_baja.png
    ./.tools/recovery/fase-ruedas/vistas/antes/curva_rapida-camara_del_juego.png
    ./.tools/recovery/fase-ruedas/vistas/antes/curva_rapida-frontal.png
    ./.tools/recovery/fase-ruedas/vistas/antes/curva_rapida-lateral.png
    ./.tools/recovery/fase-ruedas/vistas/antes/curva_rapida-rueda_delantera_der.png
    ./.tools/recovery/fase-ruedas/vistas/antes/curva_rapida-rueda_delantera_izq.png
    ./.tools/recovery/fase-ruedas/vistas/antes/curva_rapida-rueda_trasera_izq.png
    ./.tools/recovery/fase-ruedas/vistas/antes/curva_rapida-trasera_baja.png
    ./.tools/recovery/fase-ruedas/vistas/antes/frenada-camara_del_juego.png
    ./.tools/recovery/fase-ruedas/vistas/antes/frenada-frontal.png
    ./.tools/recovery/fase-ruedas/vistas/antes/frenada-lateral.png
    ./.tools/recovery/fase-ruedas/vistas/antes/frenada-rueda_delantera_der.png
    ./.tools/recovery/fase-ruedas/vistas/antes/frenada-rueda_delantera_izq.png
    ./.tools/recovery/fase-ruedas/vistas/antes/frenada-rueda_trasera_izq.png
    ./.tools/recovery/fase-ruedas/vistas/antes/frenada-trasera_baja.png
    ./.tools/recovery/fase-ruedas/vistas/antes/reposo-camara_del_juego.png
    ./.tools/recovery/fase-ruedas/vistas/antes/reposo-frontal.png
    ./.tools/recovery/fase-ruedas/vistas/antes/reposo-lateral.png
    ./.tools/recovery/fase-ruedas/vistas/antes/reposo-rueda_delantera_der.png
    ./.tools/recovery/fase-ruedas/vistas/antes/reposo-rueda_delantera_izq.png
    ./.tools/recovery/fase-ruedas/vistas/antes/reposo-rueda_trasera_izq.png
    ./.tools/recovery/fase-ruedas/vistas/antes/reposo-trasera_baja.png
    ./.tools/recovery/fase-ruedas/vistas/antes/resalto-camara_del_juego.png
    ./.tools/recovery/fase-ruedas/vistas/antes/resalto-frontal.png
    ./.tools/recovery/fase-ruedas/vistas/antes/resalto-lateral.png
    ./.tools/recovery/fase-ruedas/vistas/antes/resalto-rueda_delantera_der.png
    ./.tools/recovery/fase-ruedas/vistas/antes/resalto-rueda_delantera_izq.png
    ./.tools/recovery/fase-ruedas/vistas/antes/resalto-rueda_trasera_izq.png
    ./.tools/recovery/fase-ruedas/vistas/antes/resalto-trasera_baja.png
    ./.tools/recovery/fase-ruedas/vistas/despues/aceleracion-camara_del_juego.png
    ./.tools/recovery/fase-ruedas/vistas/despues/aceleracion-frontal.png
    ./.tools/recovery/fase-ruedas/vistas/despues/aceleracion-lateral.png
    ./.tools/recovery/fase-ruedas/vistas/despues/aceleracion-rueda_delantera_der.png
    ./.tools/recovery/fase-ruedas/vistas/despues/aceleracion-rueda_delantera_izq.png
    ./.tools/recovery/fase-ruedas/vistas/despues/aceleracion-rueda_trasera_izq.png
    ./.tools/recovery/fase-ruedas/vistas/despues/aceleracion-trasera_baja.png
    ./.tools/recovery/fase-ruedas/vistas/despues/curva_moderada-camara_del_juego.png
    ./.tools/recovery/fase-ruedas/vistas/despues/curva_moderada-frontal.png
    ./.tools/recovery/fase-ruedas/vistas/despues/curva_moderada-lateral.png
    ./.tools/recovery/fase-ruedas/vistas/despues/curva_moderada-rueda_delantera_der.png
    ./.tools/recovery/fase-ruedas/vistas/despues/curva_moderada-rueda_delantera_izq.png
    ./.tools/recovery/fase-ruedas/vistas/despues/curva_moderada-rueda_trasera_izq.png
    ./.tools/recovery/fase-ruedas/vistas/despues/curva_moderada-trasera_baja.png
    ./.tools/recovery/fase-ruedas/vistas/despues/curva_rapida-camara_del_juego.png
    ./.tools/recovery/fase-ruedas/vistas/despues/curva_rapida-frontal.png
    ./.tools/recovery/fase-ruedas/vistas/despues/curva_rapida-lateral.png
    ./.tools/recovery/fase-ruedas/vistas/despues/curva_rapida-rueda_delantera_der.png
    ./.tools/recovery/fase-ruedas/vistas/despues/curva_rapida-rueda_delantera_izq.png
    ./.tools/recovery/fase-ruedas/vistas/despues/curva_rapida-rueda_trasera_izq.png
    ./.tools/recovery/fase-ruedas/vistas/despues/curva_rapida-trasera_baja.png
    ./.tools/recovery/fase-ruedas/vistas/despues/frenada-camara_del_juego.png
    ./.tools/recovery/fase-ruedas/vistas/despues/frenada-frontal.png
    ./.tools/recovery/fase-ruedas/vistas/despues/frenada-lateral.png
    ./.tools/recovery/fase-ruedas/vistas/despues/frenada-rueda_delantera_der.png
    ./.tools/recovery/fase-ruedas/vistas/despues/frenada-rueda_delantera_izq.png
    ./.tools/recovery/fase-ruedas/vistas/despues/frenada-rueda_trasera_izq.png
    ./.tools/recovery/fase-ruedas/vistas/despues/frenada-trasera_baja.png
    ./.tools/recovery/fase-ruedas/vistas/despues/reposo-camara_del_juego.png
    ./.tools/recovery/fase-ruedas/vistas/despues/reposo-frontal.png
    ./.tools/recovery/fase-ruedas/vistas/despues/reposo-lateral.png
    ./.tools/recovery/fase-ruedas/vistas/despues/reposo-rueda_delantera_der.png
    ./.tools/recovery/fase-ruedas/vistas/despues/reposo-rueda_delantera_izq.png
    ./.tools/recovery/fase-ruedas/vistas/despues/reposo-rueda_trasera_izq.png
    ./.tools/recovery/fase-ruedas/vistas/despues/reposo-trasera_baja.png
    ./.tools/recovery/fase-ruedas/vistas/despues/resalto-camara_del_juego.png
    ./.tools/recovery/fase-ruedas/vistas/despues/resalto-frontal.png
    ./.tools/recovery/fase-ruedas/vistas/despues/resalto-lateral.png
    ./.tools/recovery/fase-ruedas/vistas/despues/resalto-rueda_delantera_der.png
    ./.tools/recovery/fase-ruedas/vistas/despues/resalto-rueda_delantera_izq.png
    ./.tools/recovery/fase-ruedas/vistas/despues/resalto-rueda_trasera_izq.png
    ./.tools/recovery/fase-ruedas/vistas/despues/resalto-trasera_baja.png
    ./.tools/recovery/fase-ruedas/vistas/ruedas/marcha-camara_del_juego.png
    ./.tools/recovery/fase-ruedas/vistas/ruedas/marcha-frontal.png
    ./.tools/recovery/fase-ruedas/vistas/ruedas/marcha-lateral.png
    ./.tools/recovery/fase-ruedas/vistas/ruedas/marcha-planta.png
    ./.tools/recovery/fase-ruedas/vistas/ruedas/marcha-rueda_delantera_izq.png
    ./.tools/recovery/fase-ruedas/vistas/ruedas/marcha-rueda_trasera_izq.png
    ./.tools/recovery/fase-ruedas/vistas/ruedas/marcha-trasera.png
    ./.tools/recovery/fase-ruedas/vistas/ruedas/marcha-trasera_baja.png
    ./.tools/recovery/fase-ruedas/vistas/ruedas/marcha-tres_cuartos.png
    ./.tools/recovery/fase-ruedas/vistas/ruedas/reposo-camara_del_juego.png
    ./.tools/recovery/fase-ruedas/vistas/ruedas/reposo-frontal.png
    ./.tools/recovery/fase-ruedas/vistas/ruedas/reposo-lateral.png
    ./.tools/recovery/fase-ruedas/vistas/ruedas/reposo-planta.png
    ./.tools/recovery/fase-ruedas/vistas/ruedas/reposo-rueda_delantera_izq.png
    ./.tools/recovery/fase-ruedas/vistas/ruedas/reposo-rueda_trasera_izq.png
    ./.tools/recovery/fase-ruedas/vistas/ruedas/reposo-trasera.png
    ./.tools/recovery/fase-ruedas/vistas/ruedas/reposo-trasera_baja.png
    ./.tools/recovery/fase-ruedas/vistas/ruedas/reposo-tres_cuartos.png
    ./.tools/recovery/fase-traseras/INFORME-FASE-TRASERAS.md
    ./.tools/recovery/fase-traseras/auditoria-antes.json
    ./.tools/recovery/fase-traseras/auditoria-despues.json
    ./.tools/recovery/fase-traseras/backup-20261015/MANIFEST.md
    ./.tools/recovery/fase-traseras/backup-20261015/SHA256SUMS
    ./.tools/recovery/fase-traseras/backup-20261015/assets/RedBull-Drive.glb
    ./.tools/recovery/fase-traseras/backup-20261015/assets/RedBull-Drive.glb.import
    ./.tools/recovery/fase-traseras/backup-20261015/assets/RedBull.tscn
    ./.tools/recovery/fase-traseras/backup-20261015/medidas-antes/bordes.txt
    ./.tools/recovery/fase-traseras/backup-20261015/medidas-antes/cobertura.txt
    ./.tools/recovery/fase-traseras/backup-20261015/medidas-antes/perfil.txt
    ./.tools/recovery/fase-traseras/backup-20261015/scripts/car_controller.gd
    ./.tools/recovery/fase-traseras/backup-20261015/scripts/wheel_suspension.gd
    ./.tools/recovery/fase-traseras/capturas-antes/curva-camara_del_juego.png
    ./.tools/recovery/fase-traseras/capturas-antes/curva-frontal.png
    ./.tools/recovery/fase-traseras/capturas-antes/curva-lateral.png
    ./.tools/recovery/fase-traseras/capturas-antes/curva-rueda_delantera.png
    ./.tools/recovery/fase-traseras/capturas-antes/curva-rueda_trasera.png
    ./.tools/recovery/fase-traseras/capturas-antes/curva-trasera.png
    ./.tools/recovery/fase-traseras/capturas-antes/curva-trasera_baja.png
    ./.tools/recovery/fase-traseras/capturas-antes/curva-tres_cuartos.png
    ./.tools/recovery/fase-traseras/capturas-antes/parado-camara_del_juego.png
    ./.tools/recovery/fase-traseras/capturas-antes/parado-frontal.png
    ./.tools/recovery/fase-traseras/capturas-antes/parado-lateral.png
    ./.tools/recovery/fase-traseras/capturas-antes/parado-rueda_delantera.png
    ./.tools/recovery/fase-traseras/capturas-antes/parado-rueda_trasera.png
    ./.tools/recovery/fase-traseras/capturas-antes/parado-trasera.png
    ./.tools/recovery/fase-traseras/capturas-antes/parado-trasera_baja.png
    ./.tools/recovery/fase-traseras/capturas-antes/parado-tres_cuartos.png
    ./.tools/recovery/fase-traseras/capturas-antes/recta-camara_del_juego.png
    ./.tools/recovery/fase-traseras/capturas-antes/recta-frontal.png
    ./.tools/recovery/fase-traseras/capturas-antes/recta-lateral.png
    ./.tools/recovery/fase-traseras/capturas-antes/recta-rueda_delantera.png
    ./.tools/recovery/fase-traseras/capturas-antes/recta-rueda_trasera.png
    ./.tools/recovery/fase-traseras/capturas-antes/recta-trasera.png
    ./.tools/recovery/fase-traseras/capturas-antes/recta-trasera_baja.png
    ./.tools/recovery/fase-traseras/capturas-antes/recta-tres_cuartos.png
    ./.tools/recovery/fase-traseras/capturas-despues/curva-camara_del_juego.png
    ./.tools/recovery/fase-traseras/capturas-despues/curva-frontal.png
    ./.tools/recovery/fase-traseras/capturas-despues/curva-lateral.png
    ./.tools/recovery/fase-traseras/capturas-despues/curva-rueda_delantera.png
    ./.tools/recovery/fase-traseras/capturas-despues/curva-rueda_trasera.png
    ./.tools/recovery/fase-traseras/capturas-despues/curva-trasera.png
    ./.tools/recovery/fase-traseras/capturas-despues/curva-trasera_baja.png
    ./.tools/recovery/fase-traseras/capturas-despues/curva-tres_cuartos.png
    ./.tools/recovery/fase-traseras/capturas-despues/parado-camara_del_juego.png
    ./.tools/recovery/fase-traseras/capturas-despues/parado-frontal.png
    ./.tools/recovery/fase-traseras/capturas-despues/parado-lateral.png
    ./.tools/recovery/fase-traseras/capturas-despues/parado-rueda_delantera.png
    ./.tools/recovery/fase-traseras/capturas-despues/parado-rueda_trasera.png
    ./.tools/recovery/fase-traseras/capturas-despues/parado-trasera.png
    ./.tools/recovery/fase-traseras/capturas-despues/parado-trasera_baja.png
    ./.tools/recovery/fase-traseras/capturas-despues/parado-tres_cuartos.png
    ./.tools/recovery/fase-traseras/capturas-despues/recta-camara_del_juego.png
    ./.tools/recovery/fase-traseras/capturas-despues/recta-frontal.png
    ./.tools/recovery/fase-traseras/capturas-despues/recta-lateral.png
    ./.tools/recovery/fase-traseras/capturas-despues/recta-rueda_delantera.png
    ./.tools/recovery/fase-traseras/capturas-despues/recta-rueda_trasera.png
    ./.tools/recovery/fase-traseras/capturas-despues/recta-trasera.png
    ./.tools/recovery/fase-traseras/capturas-despues/recta-trasera_baja.png
    ./.tools/recovery/fase-traseras/capturas-despues/recta-tres_cuartos.png
    ./.tools/recovery/fase-traseras/comparativa-ampliada.html
    ./.tools/recovery/fase-traseras/comparativa-ampliada.jpg
    ./.tools/recovery/fase-traseras/comparativa-camara-juego.html
    ./.tools/recovery/fase-traseras/comparativa-camara-juego.jpg
    ./.tools/recovery/fase-traseras/comparativa-vistas-sonda.html
    ./.tools/recovery/fase-traseras/comparativa-vistas-sonda.jpg
    ./.tools/recovery/fase-traseras/diag/diag-disp009.html
    ./.tools/recovery/fase-traseras/diag/disp009.png
    ./.tools/recovery/fase-traseras/diag/disp010.png
    ./.tools/recovery/fase-traseras/evidencia-camara/camara_pixeles-fallo.log
    ./.tools/recovery/fase-traseras/evidencia-camara/camera_pixels-despues.py
    ./.tools/recovery/fase-traseras/evidencia-camara/checks-fallo-camara-pixeles.tsv
    ./.tools/recovery/fase-traseras/evidencia-camara/dispositivo-despues.log
    ./.tools/recovery/fase-traseras/evidencia-camara/pixeles-dispositivo-fallo.json
    ./.tools/recovery/fase-traseras/evidencia-camara/valida-antes.log
    ./.tools/recovery/fase-traseras/evidencia-camara/valida-despues.log
    ./.tools/recovery/fase-traseras/evidencia-camara/verify-bateria-fallo-camara.log
    ./.tools/recovery/fase-traseras/logs/auditoria-antes.log
    ./.tools/recovery/fase-traseras/logs/auditoria-despues.log
    ./.tools/recovery/fase-traseras/logs/entrega-antes.log
    ./.tools/recovery/fase-traseras/logs/entrega-despues.log
    ./.tools/recovery/fase-traseras/logs/ruedas-antes.log
    ./.tools/recovery/fase-traseras/logs/ruedas-despues.log
    ./.tools/recovery/fase-traseras/logs/verify-fase-traseras.log
    ./.tools/recovery/fase-traseras/logs/visibilidad-antes.log
    ./.tools/recovery/fase-traseras/logs/visibilidad-despues.log
    ./.tools/recovery/fase-traseras/medidas-antes.json
    ./.tools/recovery/fase-traseras/medidas-despues.json
    ./.tools/recovery/fase-traseras/vistas-antes/marcha-camara_del_juego.png
    ./.tools/recovery/fase-traseras/vistas-antes/marcha-frontal.png
    ./.tools/recovery/fase-traseras/vistas-antes/marcha-lateral.png
    ./.tools/recovery/fase-traseras/vistas-antes/marcha-planta.png
    ./.tools/recovery/fase-traseras/vistas-antes/marcha-rueda_delantera_izq.png
    ./.tools/recovery/fase-traseras/vistas-antes/marcha-rueda_trasera_izq.png
    ./.tools/recovery/fase-traseras/vistas-antes/marcha-trasera.png
    ./.tools/recovery/fase-traseras/vistas-antes/marcha-trasera_baja.png
    ./.tools/recovery/fase-traseras/vistas-antes/marcha-tres_cuartos.png
    ./.tools/recovery/fase-traseras/vistas-despues/marcha-camara_del_juego.png
    ./.tools/recovery/fase-traseras/vistas-despues/marcha-frontal.png
    ./.tools/recovery/fase-traseras/vistas-despues/marcha-lateral.png
    ./.tools/recovery/fase-traseras/vistas-despues/marcha-planta.png
    ./.tools/recovery/fase-traseras/vistas-despues/marcha-rueda_delantera_izq.png
    ./.tools/recovery/fase-traseras/vistas-despues/marcha-rueda_trasera_izq.png
    ./.tools/recovery/fase-traseras/vistas-despues/marcha-trasera.png
    ./.tools/recovery/fase-traseras/vistas-despues/marcha-trasera_baja.png
    ./.tools/recovery/fase-traseras/vistas-despues/marcha-tres_cuartos.png
    ./.tools/recovery/fase1-colisiones/INFORME-FASE1-COLISIONES.md
    ./.tools/recovery/fase1-colisiones/apk-antes-harness.txt
    ./.tools/recovery/fase1-colisiones/car_controller-corregido.gd
    ./.tools/recovery/fase1-colisiones/control-mando/1-reposo.png
    ./.tools/recovery/fase1-colisiones/control-mando/2-desviado.png
    ./.tools/recovery/fase1-colisiones/control-mando/3-soltado.png
    ./.tools/recovery/fase1-colisiones/control-mando/cx-video-nuevo.json
    ./.tools/recovery/fase1-colisiones/logs/agarre-antes.log
    ./.tools/recovery/fase1-colisiones/logs/agarre-despues.log
    ./.tools/recovery/fase1-colisiones/logs/barrier_impact_probe-final.log
    ./.tools/recovery/fase1-colisiones/logs/collision_inventory_probe-final.log
    ./.tools/recovery/fase1-colisiones/logs/controls_probe-final.log
    ./.tools/recovery/fase1-colisiones/logs/direccion-antes.log
    ./.tools/recovery/fase1-colisiones/logs/direccion-despues.log
    ./.tools/recovery/fase1-colisiones/logs/driving_probe-final.log
    ./.tools/recovery/fase1-colisiones/logs/emulator-fase1.log
    ./.tools/recovery/fase1-colisiones/logs/export-apk.log
    ./.tools/recovery/fase1-colisiones/logs/fase3-device-1.log
    ./.tools/recovery/fase1-colisiones/logs/inventario.log
    ./.tools/recovery/fase1-colisiones/logs/lap_probe-final.log
    ./.tools/recovery/fase1-colisiones/logs/movilidad-antes.log
    ./.tools/recovery/fase1-colisiones/logs/movilidad-despues.log
    ./.tools/recovery/fase1-colisiones/logs/offtrack-antes.log
    ./.tools/recovery/fase1-colisiones/logs/offtrack_drive_probe-final.log
    ./.tools/recovery/fase1-colisiones/logs/offtrack_mobility_probe-final.log
    ./.tools/recovery/fase1-colisiones/logs/offtrack_scan_probe-final.log
    ./.tools/recovery/fase1-colisiones/logs/pbr_probe-final.log
    ./.tools/recovery/fase1-colisiones/logs/runtime_probe-final.log
    ./.tools/recovery/fase1-colisiones/logs/scan-antes.log
    ./.tools/recovery/fase1-colisiones/logs/steer_sign-final.log
    ./.tools/recovery/fase1-colisiones/logs/steering_probe-final.log
    ./.tools/recovery/fase1-colisiones/logs/surface_grip_probe-final.log
    ./.tools/recovery/fase1-colisiones/logs/track_probe-final.log
    ./.tools/recovery/fase1-colisiones/logs/ventana-resumen.txt
    ./.tools/recovery/fase1-colisiones/logs/verify-fase1-2.log
    ./.tools/recovery/fase1-colisiones/logs/verify-fase1-3.log
    ./.tools/recovery/fase1-colisiones/logs/verify-fase1-4.log
    ./.tools/recovery/fase1-colisiones/logs/verify-fase1-5.log
    ./.tools/recovery/fase1-colisiones/logs/verify-fase1-6.log
    ./.tools/recovery/fase1-colisiones/logs/verify-fase1.log
    ./.tools/recovery/fase1-colisiones/logs/visibilidad-antes.log
    ./.tools/recovery/fase1-colisiones/review/congelada-t24.png
    ./.tools/recovery/fase1-colisiones/review/pantalla-actual.png
    ./.tools/recovery/fase1-colisiones/review/review.html
    ./.tools/recovery/fase1-colisiones/shots-entrega/00-hoja-de-contacto.png
    ./.tools/recovery/fase1-colisiones/shots-entrega/01-pantalla-al-inicio.png
    ./.tools/recovery/fase1-colisiones/shots-entrega/02-pantalla-tras-conducir.png
    ./.tools/recovery/fase1-colisiones/shots-entrega/03-fases-toque-velocidad-marcha.jpg
    ./.tools/recovery/fase1-colisiones/shots-entrega/03-touch.json
    ./.tools/recovery/fase1-colisiones/shots-entrega/04-mando-antes-despues-del-fallo.png
    ./.tools/recovery/fase1-colisiones/shots-entrega/1-reposo.png
    ./.tools/recovery/fase1-colisiones/shots-entrega/2-desviado.png
    ./.tools/recovery/fase1-colisiones/shots-entrega/3-soltado.png
    ./.tools/recovery/fase1-colisiones/shots/idx0140_side1_aerea.png
    ./.tools/recovery/fase1-colisiones/shots/idx0140_side1_salida.png
    ./.tools/recovery/fase1-colisiones/shots/idx0280_side1_aerea.png
    ./.tools/recovery/fase1-colisiones/shots/idx0280_side1_salida.png
    ./.tools/recovery/fase1-colisiones/shots/idx0400_side1_aerea.png
    ./.tools/recovery/fase1-colisiones/shots/idx0400_side1_salida.png
    ./.tools/recovery/fase1-colisiones/shots/idx0480_side1_aerea.png
    ./.tools/recovery/fase1-colisiones/shots/idx0480_side1_salida.png
    ./.tools/recovery/fase1-colisiones/shots/idx1540_side1_aerea.png
    ./.tools/recovery/fase1-colisiones/shots/idx1540_side1_salida.png
    ./.tools/recovery/fase1-colisiones/shots/idx2220_side-1_aerea.png
    ./.tools/recovery/fase1-colisiones/shots/idx2220_side-1_salida.png
    ./.tools/recovery/fase1-colisiones/track_data-corregido.gd
    ./.tools/recovery/fase2-ruedas/INFORME-FASE2-RUEDAS.md
    ./.tools/recovery/fase2-ruedas/backup-20261014/MANIFEST.md
    ./.tools/recovery/fase2-ruedas/backup-20261014/SHA256SUMS
    ./.tools/recovery/fase2-ruedas/backup-20261014/assets/RedBull-Drive.glb
    ./.tools/recovery/fase2-ruedas/backup-20261014/assets/RedBull-Drive.glb.import
    ./.tools/recovery/fase2-ruedas/backup-20261014/assets/RedBull.tscn
    ./.tools/recovery/fase2-ruedas/backup-20261014/logs/apk-hashes-steering.txt
    ./.tools/recovery/fase2-ruedas/backup-20261014/medidas-antes/body-map.log
    ./.tools/recovery/fase2-ruedas/backup-20261014/medidas-antes/body-profile.log
    ./.tools/recovery/fase2-ruedas/backup-20261014/medidas-antes/body-vs-wheels.log
    ./.tools/recovery/fase2-ruedas/backup-20261014/medidas-antes/body_map.py
    ./.tools/recovery/fase2-ruedas/backup-20261014/medidas-antes/body_profile.py
    ./.tools/recovery/fase2-ruedas/backup-20261014/medidas-antes/body_vs_wheels.py
    ./.tools/recovery/fase2-ruedas/backup-20261014/medidas-antes/dump-drive.log
    ./.tools/recovery/fase2-ruedas/backup-20261014/medidas-antes/dump_glb.py
    ./.tools/recovery/fase2-ruedas/backup-20261014/medidas-antes/probe-antes.log
    ./.tools/recovery/fase2-ruedas/backup-20261014/medidas-antes/probe.log
    ./.tools/recovery/fase2-ruedas/backup-20261014/medidas-antes/wheel-geometry.log
    ./.tools/recovery/fase2-ruedas/backup-20261014/medidas-antes/wheel_geometry.py
    ./.tools/recovery/fase2-ruedas/backup-20261014/scripts/car_controller.gd
    ./.tools/recovery/fase2-ruedas/backup-20261014/scripts/gltf_model.gd
    ./.tools/recovery/fase2-ruedas/backup-20261014/scripts/race.gd
    ./.tools/recovery/fase2-ruedas/backup-20261014/scripts/track_data.gd
    ./.tools/recovery/fase2-ruedas/capturas/curva-camara_del_juego.png
    ./.tools/recovery/fase2-ruedas/capturas/curva-frontal.png
    ./.tools/recovery/fase2-ruedas/capturas/curva-lateral.png
    ./.tools/recovery/fase2-ruedas/capturas/curva-rueda_delantera.png
    ./.tools/recovery/fase2-ruedas/capturas/curva-rueda_trasera.png
    ./.tools/recovery/fase2-ruedas/capturas/curva-trasera.png
    ./.tools/recovery/fase2-ruedas/capturas/curva-trasera_baja.png
    ./.tools/recovery/fase2-ruedas/capturas/curva-tres_cuartos.png
    ./.tools/recovery/fase2-ruedas/capturas/parado-camara_del_juego.png
    ./.tools/recovery/fase2-ruedas/capturas/parado-frontal.png
    ./.tools/recovery/fase2-ruedas/capturas/parado-lateral.png
    ./.tools/recovery/fase2-ruedas/capturas/parado-rueda_delantera.png
    ./.tools/recovery/fase2-ruedas/capturas/parado-rueda_trasera.png
    ./.tools/recovery/fase2-ruedas/capturas/parado-trasera.png
    ./.tools/recovery/fase2-ruedas/capturas/parado-trasera_baja.png
    ./.tools/recovery/fase2-ruedas/capturas/parado-tres_cuartos.png
    ./.tools/recovery/fase2-ruedas/capturas/recta-camara_del_juego.png
    ./.tools/recovery/fase2-ruedas/capturas/recta-frontal.png
    ./.tools/recovery/fase2-ruedas/capturas/recta-lateral.png
    ./.tools/recovery/fase2-ruedas/capturas/recta-rueda_delantera.png
    ./.tools/recovery/fase2-ruedas/capturas/recta-rueda_trasera.png
    ./.tools/recovery/fase2-ruedas/capturas/recta-trasera.png
    ./.tools/recovery/fase2-ruedas/capturas/recta-trasera_baja.png
    ./.tools/recovery/fase2-ruedas/capturas/recta-tres_cuartos.png
    ./.tools/recovery/fase2-ruedas/disparos/comparativa-antes-despues.png
    ./.tools/recovery/fase2-ruedas/disparos/hoja-de-contacto.png
    ./.tools/recovery/fase2-ruedas/disparos/zoom-ruedas.png
    ./.tools/recovery/fase2-ruedas/hoja_contacto.py
    ./.tools/recovery/fase2-ruedas/logs/sonda_entrega.log
    ./.tools/recovery/fase2-ruedas/logs/sonda_ruedas-final.log
    ./.tools/recovery/fase2-ruedas/logs/sonda_ruedas-recheck.log
    ./.tools/recovery/fase2-ruedas/logs/sonda_ruedas.log
    ./.tools/recovery/fase2-ruedas/logs/verify-fase2.log
    ./.tools/recovery/fase2-ruedas/medidas.json
    ./.tools/recovery/fase2-ruedas/resumen-medidas.txt
    ./.tools/recovery/fase2-ruedas/vistas/marcha-camara_del_juego.png
    ./.tools/recovery/fase2-ruedas/vistas/marcha-frontal.png
    ./.tools/recovery/fase2-ruedas/vistas/marcha-lateral.png
    ./.tools/recovery/fase2-ruedas/vistas/marcha-planta.png
    ./.tools/recovery/fase2-ruedas/vistas/marcha-rueda_delantera_izq.png
    ./.tools/recovery/fase2-ruedas/vistas/marcha-rueda_trasera_izq.png
    ./.tools/recovery/fase2-ruedas/vistas/marcha-trasera.png
    ./.tools/recovery/fase2-ruedas/vistas/marcha-trasera_baja.png
    ./.tools/recovery/fase2-ruedas/vistas/marcha-tres_cuartos.png
    ./.tools/recovery/fase2-ruedas/vistas/reposo-camara_del_juego.png
    ./.tools/recovery/fase2-ruedas/vistas/reposo-frontal.png
    ./.tools/recovery/fase2-ruedas/vistas/reposo-lateral.png
    ./.tools/recovery/fase2-ruedas/vistas/reposo-planta.png
    ./.tools/recovery/fase2-ruedas/vistas/reposo-rueda_delantera_izq.png
    ./.tools/recovery/fase2-ruedas/vistas/reposo-rueda_trasera_izq.png
    ./.tools/recovery/fase2-ruedas/vistas/reposo-trasera.png
    ./.tools/recovery/fase2-ruedas/vistas/reposo-trasera_baja.png
    ./.tools/recovery/fase2-ruedas/vistas/reposo-tres_cuartos.png
    ./.tools/recovery/fase3-suspension/INFORME-FASE3-SUSPENSION.md
    ./.tools/recovery/fase3-suspension/backup-20261014/F1OneShot-fase2.apk
    ./.tools/recovery/fase3-suspension/backup-20261014/SHA256SUMS
    ./.tools/recovery/fase3-suspension/backup-20261014/assets/RedBull-Drive.glb
    ./.tools/recovery/fase3-suspension/backup-20261014/assets/RedBull-Drive.glb.import
    ./.tools/recovery/fase3-suspension/backup-20261014/assets/RedBull.tscn
    ./.tools/recovery/fase3-suspension/backup-20261014/docs/INFORME-FASE2-RUEDAS.md
    ./.tools/recovery/fase3-suspension/backup-20261014/logs/checks-fase2.tsv
    ./.tools/recovery/fase3-suspension/backup-20261014/logs/verificacion-fase2.json
    ./.tools/recovery/fase3-suspension/backup-20261014/scripts/audit_delivery.py
    ./.tools/recovery/fase3-suspension/backup-20261014/scripts/car_controller.gd
    ./.tools/recovery/fase3-suspension/backup-20261014/scripts/car_delivery_probe.gd
    ./.tools/recovery/fase3-suspension/backup-20261014/scripts/car_wheel_probe.gd
    ./.tools/recovery/fase3-suspension/backup-20261014/scripts/gltf_model.gd
    ./.tools/recovery/fase3-suspension/backup-20261014/scripts/race.gd
    ./.tools/recovery/fase3-suspension/backup-20261014/scripts/track_data.gd
    ./.tools/recovery/fase3-suspension/backup-20261014/verify.sh
    ./.tools/recovery/fase3-suspension/comparativa-camara.png
    ./.tools/recovery/fase3-suspension/comparativa-chasis.png
    ./.tools/recovery/fase3-suspension/comparativa-rueda.png
    ./.tools/recovery/fase3-suspension/empaquetado-negativo.log
    ./.tools/recovery/fase3-suspension/empaquetado-sin-script.log
    ./.tools/recovery/fase3-suspension/emulador-2400.log
    ./.tools/recovery/fase3-suspension/emulador.log
    ./.tools/recovery/fase3-suspension/estado-previo/F1OneShot-BarcelonaMoto.apk
    ./.tools/recovery/fase3-suspension/estado-previo/SHA256SUMS
    ./.tools/recovery/fase3-suspension/estado-previo/VOLVER-ATRAS.md
    ./.tools/recovery/fase3-suspension/estado-previo/estado-fase3/scripts/car_controller.gd
    ./.tools/recovery/fase3-suspension/estado-previo/estado-fase3/scripts/car_wheel_probe.gd
    ./.tools/recovery/fase3-suspension/estado-previo/estado-fase3/scripts/suspension_probe.gd
    ./.tools/recovery/fase3-suspension/estado-previo/estado-fase3/scripts/wheel_suspension.gd
    ./.tools/recovery/fase3-suspension/medidas.json
    ./.tools/recovery/fase3-suspension/montaje.py
    ./.tools/recovery/fase3-suspension/preparar_estado_previo.py
    ./.tools/recovery/fase3-suspension/sonda.log
    ./.tools/recovery/fase3-suspension/verify-fase3-antes-del-arreglo.log
    ./.tools/recovery/fase3-suspension/verify-fase3-final.log
    ./.tools/recovery/fase3-suspension/verify-fase3.log
    ./.tools/recovery/fase3-suspension/vistas/aceleracion-camara_del_juego.png
    ./.tools/recovery/fase3-suspension/vistas/aceleracion-frontal.png
    ./.tools/recovery/fase3-suspension/vistas/aceleracion-lateral.png
    ./.tools/recovery/fase3-suspension/vistas/aceleracion-rueda_delantera_der.png
    ./.tools/recovery/fase3-suspension/vistas/aceleracion-rueda_delantera_izq.png
    ./.tools/recovery/fase3-suspension/vistas/aceleracion-rueda_trasera_izq.png
    ./.tools/recovery/fase3-suspension/vistas/aceleracion-trasera_baja.png
    ./.tools/recovery/fase3-suspension/vistas/curva_moderada-camara_del_juego.png
    ./.tools/recovery/fase3-suspension/vistas/curva_moderada-frontal.png
    ./.tools/recovery/fase3-suspension/vistas/curva_moderada-lateral.png
    ./.tools/recovery/fase3-suspension/vistas/curva_moderada-rueda_delantera_der.png
    ./.tools/recovery/fase3-suspension/vistas/curva_moderada-rueda_delantera_izq.png
    ./.tools/recovery/fase3-suspension/vistas/curva_moderada-rueda_trasera_izq.png
    ./.tools/recovery/fase3-suspension/vistas/curva_moderada-trasera_baja.png
    ./.tools/recovery/fase3-suspension/vistas/curva_rapida-camara_del_juego.png
    ./.tools/recovery/fase3-suspension/vistas/curva_rapida-frontal.png
    ./.tools/recovery/fase3-suspension/vistas/curva_rapida-lateral.png
    ./.tools/recovery/fase3-suspension/vistas/curva_rapida-rueda_delantera_der.png
    ./.tools/recovery/fase3-suspension/vistas/curva_rapida-rueda_delantera_izq.png
    ./.tools/recovery/fase3-suspension/vistas/curva_rapida-rueda_trasera_izq.png
    ./.tools/recovery/fase3-suspension/vistas/curva_rapida-trasera_baja.png
    ./.tools/recovery/fase3-suspension/vistas/frenada-camara_del_juego.png
    ./.tools/recovery/fase3-suspension/vistas/frenada-frontal.png
    ./.tools/recovery/fase3-suspension/vistas/frenada-lateral.png
    ./.tools/recovery/fase3-suspension/vistas/frenada-rueda_delantera_der.png
    ./.tools/recovery/fase3-suspension/vistas/frenada-rueda_delantera_izq.png
    ./.tools/recovery/fase3-suspension/vistas/frenada-rueda_trasera_izq.png
    ./.tools/recovery/fase3-suspension/vistas/frenada-trasera_baja.png
    ./.tools/recovery/fase3-suspension/vistas/reposo-camara_del_juego.png
    ./.tools/recovery/fase3-suspension/vistas/reposo-frontal.png
    ./.tools/recovery/fase3-suspension/vistas/reposo-lateral.png
    ./.tools/recovery/fase3-suspension/vistas/reposo-rueda_delantera_der.png
    ./.tools/recovery/fase3-suspension/vistas/reposo-rueda_delantera_izq.png
    ./.tools/recovery/fase3-suspension/vistas/reposo-rueda_trasera_izq.png
    ./.tools/recovery/fase3-suspension/vistas/reposo-trasera_baja.png
    ./.tools/recovery/fase3-suspension/vistas/resalto-camara_del_juego.png
    ./.tools/recovery/fase3-suspension/vistas/resalto-frontal.png
    ./.tools/recovery/fase3-suspension/vistas/resalto-lateral.png
    ./.tools/recovery/fase3-suspension/vistas/resalto-rueda_delantera_der.png
    ./.tools/recovery/fase3-suspension/vistas/resalto-rueda_delantera_izq.png
    ./.tools/recovery/fase3-suspension/vistas/resalto-rueda_trasera_izq.png
    ./.tools/recovery/fase3-suspension/vistas/resalto-trasera_baja.png
    ./.tools/recovery/fase3/base-instalada.apk
    ./.tools/recovery/fase3/checks.tsv
    ./.tools/recovery/fase3/logs/arranque-intento.log
    ./.tools/recovery/fase3/logs/arranque.log
    ./.tools/recovery/fase3/logs/cronometro.log
    ./.tools/recovery/fase3/logs/firma.log
    ./.tools/recovery/fase3/logs/huella_instalada.log
    ./.tools/recovery/fase3/logs/instalar.log
    ./.tools/recovery/fase3/logs/lienzo.log
    ./.tools/recovery/fase3/logs/logcat-offtrack.txt
    ./.tools/recovery/fase3/logs/offtrack_dispositivo.log
    ./.tools/recovery/fase3/logs/registro.log
    ./.tools/recovery/fase3/logs/toque.log
    ./.tools/recovery/fase3/logs/toque_jar.log
    ./.tools/recovery/fase3/shots/offtrack/android-touch-offtrack.log
    ./.tools/recovery/fase3/shots/offtrack/logcat.txt
    ./.tools/recovery/fase3/shots/offtrack/offtrack.json
    ./.tools/recovery/fase3/shots/offtrack/t00.png
    ./.tools/recovery/fase3/shots/offtrack/t02.png
    ./.tools/recovery/fase3/shots/offtrack/t04.png
    ./.tools/recovery/fase3/shots/offtrack/t06.png
    ./.tools/recovery/fase3/shots/offtrack/t08.png
    ./.tools/recovery/fase3/shots/offtrack/t10.png
    ./.tools/recovery/fase3/shots/offtrack/t12.png
    ./.tools/recovery/fase3/shots/offtrack/t14.png
    ./.tools/recovery/fase3/shots/offtrack/t16.png
    ./.tools/recovery/fase3/shots/offtrack/t18.png
    ./.tools/recovery/fase3/shots/offtrack/t20.png
    ./.tools/recovery/fase3/shots/offtrack/t22.png
    ./.tools/recovery/fase3/shots/offtrack/t24.png
    ./.tools/recovery/fase3/shots/offtrack/t26.png
    ./.tools/recovery/fase3/shots/offtrack/t28.png
    ./.tools/recovery/fase3/shots/offtrack/t30.png
    ./.tools/recovery/fase3/shots/offtrack/t32.png
    ./.tools/recovery/fase3/shots/offtrack/t34.png
    ./.tools/recovery/fase3/shots/offtrack/t36.png
    ./.tools/recovery/fase3/shots/offtrack/t38.png
    ./.tools/recovery/fase3/shots/offtrack/t40.png
    ./.tools/recovery/fase3/shots/offtrack/t42.png
    ./.tools/recovery/fase3/shots/offtrack/t44.png
    ./.tools/recovery/fase3/shots/pantalla-final.png
    ./.tools/recovery/fase3/shots/reloj-1.png
    ./.tools/recovery/fase3/shots/reloj-2.png
    ./.tools/recovery/fase3/shots/toque/android-touch.log
    ./.tools/recovery/fase3/shots/toque/capture-metadata.json
    ./.tools/recovery/fase3/shots/toque/fases-velocidad-marcha.jpg
    ./.tools/recovery/fase3/shots/toque/screenrecord.log
    ./.tools/recovery/fase3/shots/toque/touch.json
    ./.tools/recovery/fase3/shots/toque/touch.mp4
    ./.tools/recovery/fase3_device.sh
    ./.tools/recovery/fase4-resoluciones/INFORME-FASE4-RESOLUCIONES.md
    ./.tools/recovery/fase4-resoluciones/emulador-perfil2-5556.log
    ./.tools/recovery/fase4-resoluciones/emulador-perfil2.log
    ./.tools/recovery/fase4-resoluciones/emulador-perfil2b.log
    ./.tools/recovery/fase4-resoluciones/emulador-perfil2c.log
    ./.tools/recovery/fase4-resoluciones/emulador-perfil2d.log
    ./.tools/recovery/fase4-resoluciones/emulador-pro-m1024.log
    ./.tools/recovery/fase4-resoluciones/emulador-pro-m1536.log
    ./.tools/recovery/fase4-resoluciones/emulador-pro-m1536.pid
    ./.tools/recovery/fase4-resoluciones/emulador-pro-noskin.log
    ./.tools/recovery/fase4-resoluciones/emulador-pro.log
    ./.tools/recovery/fase4-resoluciones/perfil1-2400x1080/checks.tsv
    ./.tools/recovery/fase4-resoluciones/perfil1-2400x1080/cronometro.log
    ./.tools/recovery/fase4-resoluciones/perfil1-2400x1080/empaquetado.log
    ./.tools/recovery/fase4-resoluciones/perfil1-2400x1080/lienzo.log
    ./.tools/recovery/fase4-resoluciones/perfil1-2400x1080/lienzo_final.log
    ./.tools/recovery/fase4-resoluciones/perfil1-2400x1080/medidas/display.txt
    ./.tools/recovery/fase4-resoluciones/perfil1-2400x1080/medidas/final-run.log
    ./.tools/recovery/fase4-resoluciones/perfil1-2400x1080/medidas/pantalla-final.png
    ./.tools/recovery/fase4-resoluciones/perfil1-2400x1080/medidas/pantalla.png
    ./.tools/recovery/fase4-resoluciones/perfil1-2400x1080/medidas/ventanas.txt
    ./.tools/recovery/fase4-resoluciones/perfil1-2400x1080/medidas/verificacion-integral.json
    ./.tools/recovery/fase4-resoluciones/perfil1-2400x1080/pantalla-final.png
    ./.tools/recovery/fase4-resoluciones/perfil1-2400x1080/pantalla.log
    ./.tools/recovery/fase4-resoluciones/perfil1-2400x1080/pantalla.png
    ./.tools/recovery/fase4-resoluciones/perfil1-2400x1080/toque.log
    ./.tools/recovery/fase4-resoluciones/perfil1-2400x1080/touch.json
    ./.tools/recovery/fase4-resoluciones/perfil1-2400x1080/verificacion-integral.json
    ./.tools/recovery/fase4-resoluciones/perfil1-2400x1080/verify.log
    ./.tools/recovery/fase4-resoluciones/perfil2-2424x1080/arranque-espera.log
    ./.tools/recovery/fase4-resoluciones/perfil2-2424x1080/checks.tsv
    ./.tools/recovery/fase4-resoluciones/perfil2-2424x1080/cronometro.log
    ./.tools/recovery/fase4-resoluciones/perfil2-2424x1080/lienzo.log
    ./.tools/recovery/fase4-resoluciones/perfil2-2424x1080/lienzo_final.log
    ./.tools/recovery/fase4-resoluciones/perfil2-2424x1080/medidas/display.txt
    ./.tools/recovery/fase4-resoluciones/perfil2-2424x1080/medidas/override-forzado-display.txt
    ./.tools/recovery/fase4-resoluciones/perfil2-2424x1080/medidas/override-forzado-ventanas.txt
    ./.tools/recovery/fase4-resoluciones/perfil2-2424x1080/medidas/override-forzado.log
    ./.tools/recovery/fase4-resoluciones/perfil2-2424x1080/medidas/pantalla-final.png
    ./.tools/recovery/fase4-resoluciones/perfil2-2424x1080/medidas/pantalla.png
    ./.tools/recovery/fase4-resoluciones/perfil2-2424x1080/medidas/ventanas.txt
    ./.tools/recovery/fase4-resoluciones/perfil2-2424x1080/pantalla-final.png
    ./.tools/recovery/fase4-resoluciones/perfil2-2424x1080/pantalla.log
    ./.tools/recovery/fase4-resoluciones/perfil2-2424x1080/pantalla.png
    ./.tools/recovery/fase4-resoluciones/perfil2-2424x1080/toque.log
    ./.tools/recovery/fase4-resoluciones/perfil2-2424x1080/touch.json
    ./.tools/recovery/fase4-resoluciones/perfil2-2424x1080/verificacion-integral.json
    ./.tools/recovery/fase4-resoluciones/perfil2-2424x1080/verify.log
    ./.tools/recovery/fase5-ruedas/backup-20261014-2130/SHA256SUMS
    ./.tools/recovery/fase5-ruedas/backup-20261014-2130/assets/RedBull-Drive.glb
    ./.tools/recovery/fase5-ruedas/backup-20261014-2130/assets/RedBull-Drive.glb.import
    ./.tools/recovery/fase5-ruedas/backup-20261014-2130/assets/RedBull.tscn
    ./.tools/recovery/fase5-ruedas/backup-20261014-2130/medidas/wheels_mesh_audit.json
    ./.tools/recovery/fase5-ruedas/backup-20261014-2130/medidas/wheels_mesh_audit.log
    ./.tools/recovery/fase5-ruedas/backup-20261014-2130/scripts/car_controller.gd
    ./.tools/recovery/fase5-ruedas/backup-20261014-2130/scripts/car_delivery_probe.gd
    ./.tools/recovery/fase5-ruedas/backup-20261014-2130/scripts/car_wheel_probe.gd
    ./.tools/recovery/fase5-ruedas/backup-20261014-2130/scripts/wheel_suspension.gd
    ./.tools/recovery/final-retest.json
    ./.tools/recovery/final-track.png
    ./.tools/recovery/handoff-evidence.json
    ./.tools/recovery/host-accelerating.png
    ./.tools/recovery/host-current.png
    ./.tools/recovery/host-render.png
    ./.tools/recovery/host-start.png
    ./.tools/recovery/inspect_import.gd
    ./.tools/recovery/install-steering.log
    ./.tools/recovery/installed-steering-retest.apk
    ./.tools/recovery/installed-steering.apk
    ./.tools/recovery/integral-run.log
    ./.tools/recovery/integral/base-instalada.apk
    ./.tools/recovery/integral/checks-1-fallo-pantalla.tsv
    ./.tools/recovery/integral/checks.tsv
    ./.tools/recovery/integral/final-run-recovery.log
    ./.tools/recovery/integral/final-run-recovery2.log
    ./.tools/recovery/integral/final-run-serial.log
    ./.tools/recovery/integral/final-run.log
    ./.tools/recovery/integral/final-summary.log
    ./.tools/recovery/integral/huellas.json
    ./.tools/recovery/integral/installed-debug.apk
    ./.tools/recovery/integral/live-1.png
    ./.tools/recovery/integral/live-2.png
    ./.tools/recovery/integral/logs/arranque-espera.log
    ./.tools/recovery/integral/logs/arranque.log
    ./.tools/recovery/integral/logs/audit_camara.log
    ./.tools/recovery/integral/logs/audit_entrega.log
    ./.tools/recovery/integral/logs/audit_materiales.log
    ./.tools/recovery/integral/logs/audit_morro.log
    ./.tools/recovery/integral/logs/audit_ruedas_malla.log
    ./.tools/recovery/integral/logs/camara_dispositivo.log
    ./.tools/recovery/integral/logs/camara_pixeles.log
    ./.tools/recovery/integral/logs/clock-final2.log
    ./.tools/recovery/integral/logs/clock-hash-final.log
    ./.tools/recovery/integral/logs/compilar.log
    ./.tools/recovery/integral/logs/cronometro.log
    ./.tools/recovery/integral/logs/display.txt
    ./.tools/recovery/integral/logs/dispositivo.log
    ./.tools/recovery/integral/logs/empaquetado.log
    ./.tools/recovery/integral/logs/final-hash-boot.log
    ./.tools/recovery/integral/logs/firma.log
    ./.tools/recovery/integral/logs/fps_anfitrion.log
    ./.tools/recovery/integral/logs/huella_apk.log
    ./.tools/recovery/integral/logs/huella_instalada.log
    ./.tools/recovery/integral/logs/instalar.log
    ./.tools/recovery/integral/logs/lienzo.log
    ./.tools/recovery/integral/logs/lienzo_final.log
    ./.tools/recovery/integral/logs/logcat-arranque.txt
    ./.tools/recovery/integral/logs/morro_dispositivo.log
    ./.tools/recovery/integral/logs/pantalla-1-fallo-rotacion.log
    ./.tools/recovery/integral/logs/pantalla.log
    ./.tools/recovery/integral/logs/registro_limpio.log
    ./.tools/recovery/integral/logs/screenrecord-test.log
    ./.tools/recovery/integral/logs/screenrecord-touch.log
    ./.tools/recovery/integral/logs/sonda_agarre.log
    ./.tools/recovery/integral/logs/sonda_camara.log
    ./.tools/recovery/integral/logs/sonda_conduccion.log
    ./.tools/recovery/integral/logs/sonda_controles.log
    ./.tools/recovery/integral/logs/sonda_direccion.log
    ./.tools/recovery/integral/logs/sonda_escapatorias.log
    ./.tools/recovery/integral/logs/sonda_impacto.log
    ./.tools/recovery/integral/logs/sonda_inventario.log
    ./.tools/recovery/integral/logs/sonda_materiales.log
    ./.tools/recovery/integral/logs/sonda_morro.log
    ./.tools/recovery/integral/logs/sonda_movilidad.log
    ./.tools/recovery/integral/logs/sonda_pista.log
    ./.tools/recovery/integral/logs/sonda_ruedas.log
    ./.tools/recovery/integral/logs/sonda_runtime.log
    ./.tools/recovery/integral/logs/sonda_sentido.log
    ./.tools/recovery/integral/logs/sonda_suspension.log
    ./.tools/recovery/integral/logs/sonda_vuelta.log
    ./.tools/recovery/integral/logs/toque-corrected.log
    ./.tools/recovery/integral/logs/toque-final.log
    ./.tools/recovery/integral/logs/toque-final2.log
    ./.tools/recovery/integral/logs/toque-final3.log
    ./.tools/recovery/integral/logs/toque-final4.log
    ./.tools/recovery/integral/logs/toque-hash-final.log
    ./.tools/recovery/integral/logs/toque.log
    ./.tools/recovery/integral/logs/toque_debug.log
    ./.tools/recovery/integral/logs/toque_final.log
    ./.tools/recovery/integral/logs/toque_jar.log
    ./.tools/recovery/integral/logs/touch-retry.log
    ./.tools/recovery/integral/logs/ventanas.txt
    ./.tools/recovery/integral/shots/camara/capturas.json
    ./.tools/recovery/integral/shots/camara/disp-001.png
    ./.tools/recovery/integral/shots/camara/disp-002.png
    ./.tools/recovery/integral/shots/camara/disp-003.png
    ./.tools/recovery/integral/shots/camara/disp-004.png
    ./.tools/recovery/integral/shots/camara/disp-005.png
    ./.tools/recovery/integral/shots/camara/disp-006.png
    ./.tools/recovery/integral/shots/camara/disp-007.png
    ./.tools/recovery/integral/shots/camara/disp-008.png
    ./.tools/recovery/integral/shots/camara/disp-009.png
    ./.tools/recovery/integral/shots/camara/disp-010.png
    ./.tools/recovery/integral/shots/camara/disp-011.png
    ./.tools/recovery/integral/shots/camara/disp-012.png
    ./.tools/recovery/integral/shots/camara/disp-013.png
    ./.tools/recovery/integral/shots/camara/disp-014.png
    ./.tools/recovery/integral/shots/camara/disp-015.png
    ./.tools/recovery/integral/shots/camara/disp-016.png
    ./.tools/recovery/integral/shots/camara/pixeles-dispositivo.json
    ./.tools/recovery/integral/shots/final-apk.png
    ./.tools/recovery/integral/shots/final-hash-screen-after.png
    ./.tools/recovery/integral/shots/final-hash-screen.png
    ./.tools/recovery/integral/shots/freno-new.png
    ./.tools/recovery/integral/shots/hud-new.png
    ./.tools/recovery/integral/shots/mando-new.png
    ./.tools/recovery/integral/shots/morro/dispositivo-morro-pedal.png
    ./.tools/recovery/integral/shots/morro/dispositivo-morro.png
    ./.tools/recovery/integral/shots/morro/dispositivo-persecucion-1.png
    ./.tools/recovery/integral/shots/morro/dispositivo-persecucion-2.png
    ./.tools/recovery/integral/shots/morro/morro-dispositivo.json
    ./.tools/recovery/integral/shots/morro/reloj-antes.png
    ./.tools/recovery/integral/shots/morro/reloj-despues.png
    ./.tools/recovery/integral/shots/now.png
    ./.tools/recovery/integral/shots/pantalla-final.png
    ./.tools/recovery/integral/shots/pantalla.png
    ./.tools/recovery/integral/shots/preexport.png
    ./.tools/recovery/integral/shots/prefinal-touch.png
    ./.tools/recovery/integral/shots/reloj-1.png
    ./.tools/recovery/integral/shots/reloj-2.png
    ./.tools/recovery/integral/shots/throttle-new.png
    ./.tools/recovery/integral/shots/toque-corrected/android-touch.log
    ./.tools/recovery/integral/shots/toque-corrected/capture-metadata.json
    ./.tools/recovery/integral/shots/toque-corrected/screenrecord.log
    ./.tools/recovery/integral/shots/toque-corrected/touch.json
    ./.tools/recovery/integral/shots/toque-corrected/touch.mp4
    ./.tools/recovery/integral/shots/toque-debug/android-touch.log
    ./.tools/recovery/integral/shots/toque-debug/screenrecord.log
    ./.tools/recovery/integral/shots/toque-debug/touch.json
    ./.tools/recovery/integral/shots/toque-debug2/screenrecord.log
    ./.tools/recovery/integral/shots/toque-debug2/touch.mp4
    ./.tools/recovery/integral/shots/toque-debug3/android-touch.log
    ./.tools/recovery/integral/shots/toque-debug3/capture-metadata.json
    ./.tools/recovery/integral/shots/toque-debug3/screenrecord.log
    ./.tools/recovery/integral/shots/toque-debug3/touch.json
    ./.tools/recovery/integral/shots/toque-debug3/touch.mp4
    ./.tools/recovery/integral/shots/toque-debug4/android-touch.log
    ./.tools/recovery/integral/shots/toque-debug4/screenrecord.log
    ./.tools/recovery/integral/shots/toque-debug4/touch.json
    ./.tools/recovery/integral/shots/toque-debug4/touch.mp4
    ./.tools/recovery/integral/shots/toque-debug5/android-touch.log
    ./.tools/recovery/integral/shots/toque-debug5/capture-metadata.json
    ./.tools/recovery/integral/shots/toque-debug5/screenrecord.log
    ./.tools/recovery/integral/shots/toque-debug5/touch.json
    ./.tools/recovery/integral/shots/toque-debug5/touch.mp4
    ./.tools/recovery/integral/shots/toque-delivery/android-touch.log
    ./.tools/recovery/integral/shots/toque-delivery/touch.json
    ./.tools/recovery/integral/shots/toque-final/android-touch.log
    ./.tools/recovery/integral/shots/toque-final/capture-metadata.json
    ./.tools/recovery/integral/shots/toque-final/fases-velocidad-marcha.jpg
    ./.tools/recovery/integral/shots/toque-final/screenrecord.log
    ./.tools/recovery/integral/shots/toque-final/touch.json
    ./.tools/recovery/integral/shots/toque-final/touch.mp4
    ./.tools/recovery/integral/shots/toque-final2/android-touch.log
    ./.tools/recovery/integral/shots/toque-final2/capture-metadata.json
    ./.tools/recovery/integral/shots/toque-final2/fases-velocidad-marcha.jpg
    ./.tools/recovery/integral/shots/toque-final2/screenrecord.log
    ./.tools/recovery/integral/shots/toque-final2/touch.json
    ./.tools/recovery/integral/shots/toque-final2/touch.mp4
    ./.tools/recovery/integral/shots/toque-final3/android-touch.log
    ./.tools/recovery/integral/shots/toque-final3/capture-metadata.json
    ./.tools/recovery/integral/shots/toque-final3/fases-velocidad-marcha.jpg
    ./.tools/recovery/integral/shots/toque-final3/screenrecord.log
    ./.tools/recovery/integral/shots/toque-final3/touch.json
    ./.tools/recovery/integral/shots/toque-final3/touch.mp4
    ./.tools/recovery/integral/shots/toque-final4/android-touch.log
    ./.tools/recovery/integral/shots/toque-final4/capture-metadata.json
    ./.tools/recovery/integral/shots/toque-final4/fases-velocidad-marcha.jpg
    ./.tools/recovery/integral/shots/toque-final4/screenrecord.log
    ./.tools/recovery/integral/shots/toque-final4/touch.json
    ./.tools/recovery/integral/shots/toque-final4/touch.mp4
    ./.tools/recovery/integral/shots/toque-geometria/android-touch.log
    ./.tools/recovery/integral/shots/toque-geometria/capture-metadata.json
    ./.tools/recovery/integral/shots/toque-geometria/fases-velocidad-marcha.jpg
    ./.tools/recovery/integral/shots/toque-geometria/screenrecord.log
    ./.tools/recovery/integral/shots/toque-geometria/touch.json
    ./.tools/recovery/integral/shots/toque-geometria/touch.mp4
    ./.tools/recovery/integral/shots/toque-geometria2/android-touch.log
    ./.tools/recovery/integral/shots/toque-geometria2/capture-metadata.json
    ./.tools/recovery/integral/shots/toque-geometria2/fases-velocidad-marcha.jpg
    ./.tools/recovery/integral/shots/toque-geometria2/screenrecord.log
    ./.tools/recovery/integral/shots/toque-geometria2/touch.json
    ./.tools/recovery/integral/shots/toque-geometria2/touch.mp4
    ./.tools/recovery/integral/shots/toque-geometria3/android-touch.log
    ./.tools/recovery/integral/shots/toque-geometria3/capture-metadata.json
    ./.tools/recovery/integral/shots/toque-geometria3/fases-velocidad-marcha.jpg
    ./.tools/recovery/integral/shots/toque-geometria3/screenrecord.log
    ./.tools/recovery/integral/shots/toque-geometria3/touch.json
    ./.tools/recovery/integral/shots/toque-geometria3/touch.mp4
    ./.tools/recovery/integral/shots/toque-geometria4/android-touch.log
    ./.tools/recovery/integral/shots/toque-geometria4/capture-metadata.json
    ./.tools/recovery/integral/shots/toque-geometria4/fases-velocidad-marcha.jpg
    ./.tools/recovery/integral/shots/toque-geometria4/screenrecord.log
    ./.tools/recovery/integral/shots/toque-geometria4/touch.json
    ./.tools/recovery/integral/shots/toque-geometria4/touch.mp4
    ./.tools/recovery/integral/shots/toque-geometria5/android-touch.log
    ./.tools/recovery/integral/shots/toque-geometria5/capture-metadata.json
    ./.tools/recovery/integral/shots/toque-geometria5/fases-velocidad-marcha.jpg
    ./.tools/recovery/integral/shots/toque-geometria5/screenrecord.log
    ./.tools/recovery/integral/shots/toque-geometria5/touch.json
    ./.tools/recovery/integral/shots/toque-geometria5/touch.mp4
    ./.tools/recovery/integral/shots/toque-hash-final/android-touch.log
    ./.tools/recovery/integral/shots/toque-hash-final/capture-metadata.json
    ./.tools/recovery/integral/shots/toque-hash-final/fases-velocidad-marcha.jpg
    ./.tools/recovery/integral/shots/toque-hash-final/screenrecord.log
    ./.tools/recovery/integral/shots/toque-hash-final/touch.json
    ./.tools/recovery/integral/shots/toque-hash-final/touch.mp4
    ./.tools/recovery/integral/shots/toque-live/android-touch.log
    ./.tools/recovery/integral/shots/toque-live/capture-metadata.json
    ./.tools/recovery/integral/shots/toque-live/touch.mp4
    ./.tools/recovery/integral/shots/toque-recovery/android-touch.log
    ./.tools/recovery/integral/shots/toque-recovery/screenrecord.log
    ./.tools/recovery/integral/shots/toque-recovery/touch.h264
    ./.tools/recovery/integral/shots/toque-recovery/touch.json
    ./.tools/recovery/integral/shots/toque-retry/android-touch.log
    ./.tools/recovery/integral/shots/toque-retry/frame-0.png
    ./.tools/recovery/integral/shots/toque-retry/frame-00.png
    ./.tools/recovery/integral/shots/toque-retry/frame-01.png
    ./.tools/recovery/integral/shots/toque-retry/frame-03.png
    ./.tools/recovery/integral/shots/toque-retry/frame-05.png
    ./.tools/recovery/integral/shots/toque-retry/frame-08.png
    ./.tools/recovery/integral/shots/toque-retry/frame-10.png
    ./.tools/recovery/integral/shots/toque-retry/frame-12.png
    ./.tools/recovery/integral/shots/toque-retry/frame-15.png
    ./.tools/recovery/integral/shots/toque-retry/frame-18.png
    ./.tools/recovery/integral/shots/toque-retry/frame-20.png
    ./.tools/recovery/integral/shots/toque-retry/frame-23.png
    ./.tools/recovery/integral/shots/toque-retry/frame-26.png
    ./.tools/recovery/integral/shots/toque-retry/frame-28.png
    ./.tools/recovery/integral/shots/toque-retry/frame-30.png
    ./.tools/recovery/integral/shots/toque-retry/frame-33.png
    ./.tools/recovery/integral/shots/toque-retry/frame-36.png
    ./.tools/recovery/integral/shots/toque-retry/frame-38.png
    ./.tools/recovery/integral/shots/toque-retry/frame-40.png
    ./.tools/recovery/integral/shots/toque-retry/frame-43.png
    ./.tools/recovery/integral/shots/toque-retry/frame-45.png
    ./.tools/recovery/integral/shots/toque-retry/sample-00.png
    ./.tools/recovery/integral/shots/toque-retry/sample-02.png
    ./.tools/recovery/integral/shots/toque-retry/sample-04.png
    ./.tools/recovery/integral/shots/toque-retry/sample-06.png
    ./.tools/recovery/integral/shots/toque-retry/sample-08.png
    ./.tools/recovery/integral/shots/toque-retry/sample-10.png
    ./.tools/recovery/integral/shots/toque-retry/sample-12.png
    ./.tools/recovery/integral/shots/toque-retry/sample-14.png
    ./.tools/recovery/integral/shots/toque-retry/sample-16.png
    ./.tools/recovery/integral/shots/toque-retry/sample-18.png
    ./.tools/recovery/integral/shots/toque-retry/sample-20.png
    ./.tools/recovery/integral/shots/toque-retry/sample-22.png
    ./.tools/recovery/integral/shots/toque-retry/sample-24.png
    ./.tools/recovery/integral/shots/toque-retry/sample-26.png
    ./.tools/recovery/integral/shots/toque-retry/sample-28.png
    ./.tools/recovery/integral/shots/toque-retry/sample-30.png
    ./.tools/recovery/integral/shots/toque-retry/sample-32.png
    ./.tools/recovery/integral/shots/toque-retry/sample-34.png
    ./.tools/recovery/integral/shots/toque-retry/sample-36.png
    ./.tools/recovery/integral/shots/toque-retry/sample-38.png
    ./.tools/recovery/integral/shots/toque-retry/sample-40.png
    ./.tools/recovery/integral/shots/toque-retry/sample-42.png
    ./.tools/recovery/integral/shots/toque-retry/sample-44.png
    ./.tools/recovery/integral/shots/toque-retry/sample-46.png
    ./.tools/recovery/integral/shots/toque-retry/test.mp4
    ./.tools/recovery/integral/shots/toque-retry/touch.mp4
    ./.tools/recovery/integral/shots/toque-verified/android-touch.log
    ./.tools/recovery/integral/shots/toque-verified/capture-metadata.json
    ./.tools/recovery/integral/shots/toque-verified/touch.json
    ./.tools/recovery/integral/shots/toque-verified/touch.mp4
    ./.tools/recovery/integral/shots/toque/android-touch.log
    ./.tools/recovery/integral/shots/toque/capture-metadata.json
    ./.tools/recovery/integral/shots/toque/fases-velocidad-marcha.jpg
    ./.tools/recovery/integral/shots/toque/screenrecord.log
    ./.tools/recovery/integral/shots/toque/touch.json
    ./.tools/recovery/integral/shots/toque/touch.mp4
    ./.tools/recovery/integral/verificacion-integral.json
    ./.tools/recovery/integral/verify-run-2.log
    ./.tools/recovery/integral_report.py
    ./.tools/recovery/java-offtrack/AndroidTouchOfftrack.class
    ./.tools/recovery/java/AndroidTouch.class
    ./.tools/recovery/joystick-montaje.png
    ./.tools/recovery/lap-probe-steering.log
    ./.tools/recovery/lap-retest.log
    ./.tools/recovery/launch-steering.log
    ./.tools/recovery/logcat-steering-boot.txt
    ./.tools/recovery/logs/android-export-definitivo.log
    ./.tools/recovery/logs/android-export-final.log
    ./.tools/recovery/logs/android-export.log
    ./.tools/recovery/logs/android-frames.txt
    ./.tools/recovery/logs/android-input-devices.txt
    ./.tools/recovery/logs/android-install-final.log
    ./.tools/recovery/logs/android-multitouch.log
    ./.tools/recovery/logs/android-runtime-final.log
    ./.tools/recovery/logs/android-runtime.log
    ./.tools/recovery/logs/android-window-final.txt
    ./.tools/recovery/logs/android-window.txt
    ./.tools/recovery/logs/apk-fps-5556.txt
    ./.tools/recovery/logs/apk-signature.log
    ./.tools/recovery/logs/artifact-audit.log
    ./.tools/recovery/logs/bateria-1-fallo-pantalla.log
    ./.tools/recovery/logs/blender-car.log
    ./.tools/recovery/logs/blender-pbr.log
    ./.tools/recovery/logs/blender-track.log
    ./.tools/recovery/logs/check-car_controller.log
    ./.tools/recovery/logs/check-gltf_model.log
    ./.tools/recovery/logs/check-race.log
    ./.tools/recovery/logs/check-race_hud.log
    ./.tools/recovery/logs/check-touch_controls.log
    ./.tools/recovery/logs/check-track_data.log
    ./.tools/recovery/logs/controls.log
    ./.tools/recovery/logs/controls_probe-final.log
    ./.tools/recovery/logs/driving-final.log
    ./.tools/recovery/logs/driving.log
    ./.tools/recovery/logs/editor-final.log
    ./.tools/recovery/logs/emulator-host.log
    ./.tools/recovery/logs/final-controls_probe.log
    ./.tools/recovery/logs/final-lap_probe.log
    ./.tools/recovery/logs/final-runtime_probe.log
    ./.tools/recovery/logs/final-track_probe.log
    ./.tools/recovery/logs/godot-import-pbr.log
    ./.tools/recovery/logs/godot-import.log
    ./.tools/recovery/logs/host-install.log
    ./.tools/recovery/logs/host-runtime.log
    ./.tools/recovery/logs/host-surface.txt
    ./.tools/recovery/logs/host-window.txt
    ./.tools/recovery/logs/kn5-tool-check.log
    ./.tools/recovery/logs/lap.log
    ./.tools/recovery/logs/lap_probe-final.log
    ./.tools/recovery/logs/obj-validation.log
    ./.tools/recovery/logs/pbr-probe.log
    ./.tools/recovery/logs/pbr-review-delivered.log
    ./.tools/recovery/logs/pbr-review-tarmac.log
    ./.tools/recovery/logs/pbr-review-uniform.log
    ./.tools/recovery/logs/review-server.log
    ./.tools/recovery/logs/runtime.log
    ./.tools/recovery/logs/runtime_probe-final.log
    ./.tools/recovery/logs/scene-import-inspect.log
    ./.tools/recovery/logs/screencap-err.txt
    ./.tools/recovery/logs/source-degenerate-triangles.txt
    ./.tools/recovery/logs/touch-final.log
    ./.tools/recovery/logs/track_probe-final.log
    ./.tools/recovery/logs/verify-controls_probe.log
    ./.tools/recovery/logs/verify-driving.log
    ./.tools/recovery/logs/verify-lap_probe.log
    ./.tools/recovery/logs/verify-runtime_probe.log
    ./.tools/recovery/logs/verify-track_probe.log
    ./.tools/recovery/material_audit.json
    ./.tools/recovery/obj_validation_removed_faces.json
    ./.tools/recovery/offtrack-audit-final.log
    ./.tools/recovery/offtrack-audit-initial.log
    ./.tools/recovery/offtrack-audit-steering.log
    ./.tools/recovery/offtrack-drive-1.log
    ./.tools/recovery/offtrack-drive-2.log
    ./.tools/recovery/offtrack-drive-3.log
    ./.tools/recovery/offtrack-drive-4.log
    ./.tools/recovery/offtrack-drive-5.log
    ./.tools/recovery/offtrack_device_check.py
    ./.tools/recovery/offtrack_probe.gd
    ./.tools/recovery/origen-captura-aerea/INFORME-CAPTURA-AEREA.md
    ./.tools/recovery/origen-captura-aerea/SHA256SUMS
    ./.tools/recovery/origen-captura-aerea/_test-host.png
    ./.tools/recovery/origen-captura-aerea/apk-en-ejecucion.png
    ./.tools/recovery/origen-captura-aerea/candidatas-unity-nuevas/remastered-first-chicane.png
    ./.tools/recovery/origen-captura-aerea/candidatas-unity-nuevas/remastered-long-right-oblique.png
    ./.tools/recovery/origen-captura-aerea/candidatas-unity-nuevas/remastered-overview.png
    ./.tools/recovery/origen-captura-aerea/candidatas-unity-nuevas/six-views-contact-sheet.jpg
    ./.tools/recovery/origen-captura-aerea/candidatas-unity-nuevas/unity-final-contact-sheet.jpg
    ./.tools/recovery/origen-captura-aerea/candidatas-unity-nuevas/visual-review.html
    ./.tools/recovery/origen-captura-aerea/candidatas/barcelona-class-top.png
    ./.tools/recovery/origen-captura-aerea/candidatas/barcelona-visual-long-right-top.png
    ./.tools/recovery/origen-captura-aerea/candidatas/blender-visual-kn5-top.png
    ./.tools/recovery/origen-captura-aerea/candidatas/godot-first-chicane.png
    ./.tools/recovery/origen-captura-aerea/candidatas/godot-long-right-hander.png
    ./.tools/recovery/origen-captura-aerea/candidatas/godot-main-straight.png
    ./.tools/recovery/origen-captura-aerea/candidatas/godot-overview.png
    ./.tools/recovery/origen-captura-aerea/candidatas/godot-track-limits.png
    ./.tools/recovery/origen-captura-aerea/candidatas/test-top.png
    ./.tools/recovery/origen-captura-aerea/crop-derecha.png
    ./.tools/recovery/origen-captura-aerea/crop-dock.png
    ./.tools/recovery/origen-captura-aerea/crop-region-editor.png
    ./.tools/recovery/origen-captura-aerea/crops/coche-marcado-apk-en-ejecucion.png
    ./.tools/recovery/origen-captura-aerea/crops/coche-marcado-shot-apk-recuperado-final.png
    ./.tools/recovery/origen-captura-aerea/crops/coche-marcado-viewport-godot-editor.png
    ./.tools/recovery/origen-captura-aerea/crops/editor-arriva-x2.png
    ./.tools/recovery/origen-captura-aerea/crops/editor-centro-x2.png
    ./.tools/recovery/origen-captura-aerea/crops/gestor-completo.png
    ./.tools/recovery/origen-captura-aerea/crops/gestor-proyectos-x2.png
    ./.tools/recovery/origen-captura-aerea/crops/safari-barra-x2.png
    ./.tools/recovery/origen-captura-aerea/crops/unity-overview-zoom.png
    ./.tools/recovery/origen-captura-aerea/editor-corrida.log
    ./.tools/recovery/origen-captura-aerea/editor.pid
    ./.tools/recovery/origen-captura-aerea/escritorio-01.png
    ./.tools/recovery/origen-captura-aerea/host-con-editor.png
    ./.tools/recovery/origen-captura-aerea/host-editor-front.png
    ./.tools/recovery/origen-captura-aerea/host-editor-ventana.png
    ./.tools/recovery/origen-captura-aerea/informe.html
    ./.tools/recovery/origen-captura-aerea/informe.py
    ./.tools/recovery/origen-captura-aerea/marcar_coche.py
    ./.tools/recovery/origen-captura-aerea/mediciones.log
    ./.tools/recovery/origen-captura-aerea/medir_vistas.py
    ./.tools/recovery/origen-captura-aerea/revisar.html
    ./.tools/recovery/origen-captura-aerea/serve.log
    ./.tools/recovery/origen-captura-aerea/serve.pid
    ./.tools/recovery/origen-captura-aerea/tablero.html
    ./.tools/recovery/origen-captura-aerea/tira-0.png
    ./.tools/recovery/origen-captura-aerea/tira-1.png
    ./.tools/recovery/origen-captura-aerea/tira-2.png
    ./.tools/recovery/origen-captura-aerea/tira-3.png
    ./.tools/recovery/origen-captura-aerea/txt-centro.png
    ./.tools/recovery/origen-captura-aerea/txt-izq.png
    ./.tools/recovery/origen-captura-aerea/txt-omnibox.png
    ./.tools/recovery/origen-captura-aerea/ventanas.txt
    ./.tools/recovery/origen-captura-aerea/ventanas/blender.png
    ./.tools/recovery/origen-captura-aerea/ventanas/freebuff.png
    ./.tools/recovery/origen-captura-aerea/ventanas/godot-editor.png
    ./.tools/recovery/origen-captura-aerea/ventanas/godot-gestor.png
    ./.tools/recovery/origen-captura-aerea/ventanas/safari.png
    ./.tools/recovery/origen-captura-aerea/ver.html
    ./.tools/recovery/origen-captura-aerea/ver.py
    ./.tools/recovery/origen-captura-aerea/viewport-editor-1a1.png
    ./.tools/recovery/origen-captura-aerea/viewport-godot-editor.png
    ./.tools/recovery/origen-captura-aerea/vistas.html
    ./.tools/recovery/origen-captura-aerea/winlist
    ./.tools/recovery/origen-captura-aerea/winlist.swift
    ./.tools/recovery/origen-captura-aerea/zoom-derecha-_test-host.png
    ./.tools/recovery/origen-captura-aerea/zoom-derecha-host-con-editor.png
    ./.tools/recovery/origen-captura-aerea/zoom-izquierda-_test-host.png
    ./.tools/recovery/origen-captura-aerea/zoom-izquierda-host-con-editor.png
    ./.tools/recovery/package-path-steering.txt
    ./.tools/recovery/pbr/device-before.png
    ./.tools/recovery/pbr/map_channels.json
    ./.tools/recovery/pbr/material_roughness.json
    ./.tools/recovery/pbr/render-delivered.png
    ./.tools/recovery/pbr/render-tarmac.png
    ./.tools/recovery/pbr/render-uniform85.png
    ./.tools/recovery/pbr/review-ab.html
    ./.tools/recovery/pbr/review-embedded.html
    ./.tools/recovery/pbr/review-stacked.html
    ./.tools/recovery/pbr/review.html
    ./.tools/recovery/pbr/road-delivered.png
    ./.tools/recovery/pbr/road-device-before.png
    ./.tools/recovery/pbr/road-tarmac-folded.png
    ./.tools/recovery/pbr/road-uniform85.png
    ./.tools/recovery/pbr/roughness/BricksWall_MAP.png
    ./.tools/recovery/pbr/roughness/GrandStand_base_MAP.png
    ./.tools/recovery/pbr/roughness/Wood_plank_MAP.png
    ./.tools/recovery/pbr/roughness/asph-red_MAP.png
    ./.tools/recovery/pbr/roughness/box-wall_MAP.png
    ./.tools/recovery/pbr/roughness/box1_MAP.png
    ./.tools/recovery/pbr/roughness/bridge2_MAP.png
    ./.tools/recovery/pbr/roughness/bridge_1B_MAP.png
    ./.tools/recovery/pbr/roughness/carpet-base_MAP.png
    ./.tools/recovery/pbr/roughness/concrete_box_MAP.png
    ./.tools/recovery/pbr/roughness/distanz_MAP.png
    ./.tools/recovery/pbr/roughness/grail_MAP.png
    ./.tools/recovery/pbr/roughness/grass2_MAP.png
    ./.tools/recovery/pbr/roughness/grille2_MAP.png
    ./.tools/recovery/pbr/roughness/grille_MAP.png
    ./.tools/recovery/pbr/roughness/gstand-detail3_MAP.png
    ./.tools/recovery/pbr/roughness/marshall-box_MAP.png
    ./.tools/recovery/pbr/roughness/roof-tile_MAP.png
    ./.tools/recovery/pbr/roughness/sand_base_MAP.png
    ./.tools/recovery/pbr/roughness/slow-curb_MAP.png
    ./.tools/recovery/pbr/roughness/structures-base_MAP.png
    ./.tools/recovery/pbr/roughness/walls1_MAP.png
    ./.tools/recovery/pbr/roughness_manifest.json
    ./.tools/recovery/pbr/track_material_audit.json
    ./.tools/recovery/pbr/view-delivered.png
    ./.tools/recovery/pbr/view-device-before.png
    ./.tools/recovery/pbr/view-tarmac-folded.png
    ./.tools/recovery/pbr/view-uniform85.png
    ./.tools/recovery/pbr_review.gd
    ./.tools/recovery/prepare_sources.py
    ./.tools/recovery/pull-steering.log
    ./.tools/recovery/reloj-1-reloj.png
    ./.tools/recovery/reloj-1.png
    ./.tools/recovery/reloj-2-reloj.png
    ./.tools/recovery/reloj-2.png
    ./.tools/recovery/reloj-comparativa.png
    ./.tools/recovery/render-probe-steering.log
    ./.tools/recovery/revert/INFORME-REVERSION.md
    ./.tools/recovery/revert/backup-20261013-2300/MANIFEST.md
    ./.tools/recovery/revert/backup-20261013-2300/SHA256SUMS
    ./.tools/recovery/revert/backup-20261013-2300/apk/F1OneShot-BarcelonaMoto-ddbf65.apk
    ./.tools/recovery/revert/backup-20261013-2300/estado-antes-de-revertir.png
    ./.tools/recovery/revert/backup-20261013-2300/logs-intervencion/barrier-impact-1.log
    ./.tools/recovery/revert/backup-20261013-2300/logs-intervencion/barrier-impact-2.log
    ./.tools/recovery/revert/backup-20261013-2300/logs-intervencion/offtrack-audit-steering.log
    ./.tools/recovery/revert/backup-20261013-2300/logs-intervencion/offtrack-drive-1.log
    ./.tools/recovery/revert/backup-20261013-2300/logs-intervencion/offtrack-drive-2.log
    ./.tools/recovery/revert/backup-20261013-2300/logs-intervencion/offtrack-drive-3.log
    ./.tools/recovery/revert/backup-20261013-2300/logs-intervencion/offtrack-drive-4.log
    ./.tools/recovery/revert/backup-20261013-2300/logs-intervencion/offtrack-drive-5.log
    ./.tools/recovery/revert/backup-20261013-2300/logs-intervencion/steering-parse-final.log
    ./.tools/recovery/revert/backup-20261013-2300/logs-intervencion/steering-probe-1.log
    ./.tools/recovery/revert/backup-20261013-2300/logs-intervencion/steering-probe-2.log
    ./.tools/recovery/revert/backup-20261013-2300/logs-intervencion/steering-probe-3.log
    ./.tools/recovery/revert/backup-20261013-2300/scripts-intervencion/controls_probe.gd
    ./.tools/recovery/revert/backup-20261013-2300/scripts-intervencion/dynamics_probe.gd
    ./.tools/recovery/revert/backup-20261013-2300/scripts-intervencion/race.gd
    ./.tools/recovery/revert/backup-20261013-2300/scripts-intervencion/touch_controls.gd
    ./.tools/recovery/revert/backup-20261013-2300/scripts/barrier_impact_probe.gd
    ./.tools/recovery/revert/backup-20261013-2300/scripts/car_controller.gd
    ./.tools/recovery/revert/backup-20261013-2300/scripts/offtrack_drive_probe.gd
    ./.tools/recovery/revert/backup-20261013-2300/scripts/steering_probe.gd
    ./.tools/recovery/revert/backup-20261013-2300/tools-recovery/AndroidTouch.java
    ./.tools/recovery/revert/backup-20261013-2300/tools-recovery/offtrack_probe.gd
    ./.tools/recovery/revert/backup-20261013-2300/tools-recovery/screen_check.py
    ./.tools/recovery/revert/base-instalada-final.apk
    ./.tools/recovery/revert/base-instalada-recuperada.apk
    ./.tools/recovery/revert/comparar.html
    ./.tools/recovery/revert/comparar_vistas.py
    ./.tools/recovery/revert/controls-probe-final.log
    ./.tools/recovery/revert/controls-probe-recuperado.log
    ./.tools/recovery/revert/driving-probe-final.log
    ./.tools/recovery/revert/estado-antes-de-revertir.png
    ./.tools/recovery/revert/export-final.log
    ./.tools/recovery/revert/export-recuperado.log
    ./.tools/recovery/revert/host-render-antes.png
    ./.tools/recovery/revert/ready-final.log
    ./.tools/recovery/revert/ready-poll.log
    ./.tools/recovery/revert/render-probe-recuperado.log
    ./.tools/recovery/revert/serve.log
    ./.tools/recovery/revert/serve.pid
    ./.tools/recovery/revert/shot-apk-recuperado-final.png
    ./.tools/recovery/revert/shot-apk-recuperado.png
    ./.tools/recovery/revert/touch-regresion.log
    ./.tools/recovery/revert/touch-regresion/android-touch.log
    ./.tools/recovery/revert/touch-regresion/capture-metadata.json
    ./.tools/recovery/revert/touch-regresion/fases-velocidad-marcha.jpg
    ./.tools/recovery/revert/touch-regresion/screenrecord.log
    ./.tools/recovery/revert/touch-regresion/touch.json
    ./.tools/recovery/revert/touch-regresion/touch.mp4
    ./.tools/recovery/revert/track-probe-final.log
    ./.tools/recovery/revert/track-probe-recuperado.log
    ./.tools/recovery/revert/verificar-vista.log
    ./.tools/recovery/revert/verificar_vista.gd
    ./.tools/recovery/revert/vista-final.log
    ./.tools/recovery/revert/vista-juego-recuperada.png
    ./.tools/recovery/review.html
    ./.tools/recovery/review/c2-card.png
    ./.tools/recovery/review/c2-clock.png
    ./.tools/recovery/review/c3-card.png
    ./.tools/recovery/review/c3-clock.png
    ./.tools/recovery/review/clock-after.png
    ./.tools/recovery/review/clock-before.png
    ./.tools/recovery/review/crops/inicio.png
    ./.tools/recovery/review/crops/mando-comparacion.png
    ./.tools/recovery/review/crops/mando-offtrack-zoom.png
    ./.tools/recovery/review/crops/mando-offtrack.png
    ./.tools/recovery/review/crops/tras-conducir.png
    ./.tools/recovery/review/dev-after.png
    ./.tools/recovery/review/dev-before.png
    ./.tools/recovery/review/fase1-entrega.html
    ./.tools/recovery/review/final-screen.html
    ./.tools/recovery/review/freno-new.png
    ./.tools/recovery/review/full-after.png
    ./.tools/recovery/review/full-before.png
    ./.tools/recovery/review/hud-new.png
    ./.tools/recovery/review/mando-new.png
    ./.tools/recovery/review/review-controls.html
    ./.tools/recovery/review/review2.html
    ./.tools/recovery/review/throttle-new.png
    ./.tools/recovery/revision-rueda-trasera-detalle.html
    ./.tools/recovery/revision-rueda-trasera-detalle.jpg
    ./.tools/recovery/revision-ruedas-completo.html
    ./.tools/recovery/revision-ruedas-completo.jpg
    ./.tools/recovery/revision-ruedas-zoom.html
    ./.tools/recovery/revision-ruedas-zoom.jpg
    ./.tools/recovery/revision-traseras-aparato.html
    ./.tools/recovery/revision-traseras-aparato.jpg
    ./.tools/recovery/revision-traseras-hoja.html
    ./.tools/recovery/revision-traseras.html
    ./.tools/recovery/revision-traseras.jpg
    ./.tools/recovery/runtime-probe-steering.log
    ./.tools/recovery/runtime-retest.log
    ./.tools/recovery/screen-layout-steering-final.log
    ./.tools/recovery/screen_check.py
    ./.tools/recovery/screen_geometry.py
    ./.tools/recovery/shots-steering-installed-final.png
    ./.tools/recovery/shots-steering-start.png
    ./.tools/recovery/shots/crop-lap-panel.png
    ./.tools/recovery/shots/now-small.png
    ./.tools/recovery/shots/now.png
    ./.tools/recovery/source_metadata.json
    ./.tools/recovery/stable-20261014-pre-colisiones/F1OneShot-BarcelonaMoto-605abf6a.apk
    ./.tools/recovery/stable-20261014-pre-colisiones/SHA256SUMS
    ./.tools/recovery/stable-20261014-pre-colisiones/scenes/race.tscn
    ./.tools/recovery/stable-20261014-pre-colisiones/scripts/car_controller.gd
    ./.tools/recovery/stable-20261014-pre-colisiones/scripts/controls_probe.gd
    ./.tools/recovery/stable-20261014-pre-colisiones/scripts/driving_probe.gd
    ./.tools/recovery/stable-20261014-pre-colisiones/scripts/lap_probe.gd
    ./.tools/recovery/stable-20261014-pre-colisiones/scripts/race.gd
    ./.tools/recovery/stable-20261014-pre-colisiones/scripts/runtime_probe.gd
    ./.tools/recovery/stable-20261014-pre-colisiones/scripts/touch_controls.gd
    ./.tools/recovery/stable-20261014-pre-colisiones/scripts/track_data.gd
    ./.tools/recovery/stable-20261014-pre-colisiones/steering_probe-archivada.gd
    ./.tools/recovery/stable-20261014-pre-colisiones/tools-recovery/check_logcat.py
    ./.tools/recovery/stable-20261014-pre-colisiones/tools-recovery/integral_report.py
    ./.tools/recovery/stable-20261014-pre-colisiones/tools-recovery/screen_check.py
    ./.tools/recovery/stable-20261014-pre-colisiones/verify.sh
    ./.tools/recovery/stable-before-offtrack-steering/F1OneShot-BarcelonaMoto.apk
    ./.tools/recovery/stable-before-offtrack-steering/SHA256SUMS
    ./.tools/recovery/stable-before-offtrack-steering/car_controller.gd
    ./.tools/recovery/stable-before-offtrack-steering/controls_probe.gd
    ./.tools/recovery/stable-before-offtrack-steering/driving_probe.gd
    ./.tools/recovery/stable-before-offtrack-steering/race.gd
    ./.tools/recovery/stable-before-offtrack-steering/race.tscn
    ./.tools/recovery/stable-before-offtrack-steering/touch_controls.gd
    ./.tools/recovery/steering-parse-final.log
    ./.tools/recovery/steering-parse.log
    ./.tools/recovery/steering-probe-1.log
    ./.tools/recovery/steering-probe-2.log
    ./.tools/recovery/steering-probe-3.log
    ./.tools/recovery/track-probe-steering.log
    ./.tools/recovery/track-retest.log
    ./.tools/recovery/verificacion-final.json
    ./.tools/recovery/wheels_mesh_audit.json
    ./.tools/recovery/wheels_mesh_audit.log
    ./.tools/runtime-probe.log
    ./.tools/runtime-probe2.log
    ./.tools/runtime-probe3.log
    ./.tools/runtime-probe4.log
    ./.tools/stable/BarcelonaMoto-Tutorial-pre-PBR.glb
    ./.tools/stable/F1OneShot-BarcelonaMoto-pre-PBR.apk
    ./.tools/stable/MANIFEST-pre-PBR.txt
    ./.tools/stable/RedBull-Drive-pre-PBR.glb
    ./.tools/stable/import_obj-pre-PBR.py
    ./.tools/stale-conversion/BarcelonaMoto.glb
    ./.tools/stale-conversion/BarcelonaMoto.glb.import
    ./.tools/stale-conversion/BarcelonaMoto_3dt3B.png
    ./.tools/stale-conversion/BarcelonaMoto_3dt3B.png.import
    ./.tools/stale-conversion/BarcelonaMoto_Barcellona_Box_A.png
    ./.tools/stale-conversion/BarcelonaMoto_Barcellona_Box_A.png.import
    ./.tools/stale-conversion/BarcelonaMoto_BricksWall.png
    ./.tools/stale-conversion/BarcelonaMoto_BricksWall.png.import
    ./.tools/stale-conversion/BarcelonaMoto_BricksWall_MAP_rough4.png
    ./.tools/stale-conversion/BarcelonaMoto_BricksWall_MAP_rough4.png.import
    ./.tools/stale-conversion/BarcelonaMoto_BricksWall_NM.png
    ./.tools/stale-conversion/BarcelonaMoto_BricksWall_NM.png.import
    ./.tools/stale-conversion/BarcelonaMoto_Concrete_wall.png
    ./.tools/stale-conversion/BarcelonaMoto_Concrete_wall.png.import
    ./.tools/stale-conversion/BarcelonaMoto_DRIVER_Face.png
    ./.tools/stale-conversion/BarcelonaMoto_DRIVER_Face.png.import
    ./.tools/stale-conversion/BarcelonaMoto_DRIVER_Suit.png
    ./.tools/stale-conversion/BarcelonaMoto_DRIVER_Suit.png.import
    ./.tools/stale-conversion/BarcelonaMoto_Garage_Colour.png
    ./.tools/stale-conversion/BarcelonaMoto_Garage_Colour.png.import
    ./.tools/stale-conversion/BarcelonaMoto_GrandStand_base.png
    ./.tools/stale-conversion/BarcelonaMoto_GrandStand_base.png.import
    ./.tools/stale-conversion/BarcelonaMoto_GrandStand_base_MAP_rough1.png
    ./.tools/stale-conversion/BarcelonaMoto_GrandStand_base_MAP_rough1.png.import
    ./.tools/stale-conversion/BarcelonaMoto_GrandStand_base_MAP_rough2.png
    ./.tools/stale-conversion/BarcelonaMoto_GrandStand_base_MAP_rough2.png.import
    ./.tools/stale-conversion/BarcelonaMoto_GrandStand_base_MAP_rough44.png
    ./.tools/stale-conversion/BarcelonaMoto_GrandStand_base_MAP_rough44.png.import
    ./.tools/stale-conversion/BarcelonaMoto_GrandStand_base_NMW5.png
    ./.tools/stale-conversion/BarcelonaMoto_GrandStand_base_NMW5.png.import
    ./.tools/stale-conversion/BarcelonaMoto_Lights_Emissive_DIF.png
    ./.tools/stale-conversion/BarcelonaMoto_Lights_Emissive_DIF.png.import
    ./.tools/stale-conversion/BarcelonaMoto_NULL.png
    ./.tools/stale-conversion/BarcelonaMoto_NULL.png.import
    ./.tools/stale-conversion/BarcelonaMoto_Props_PITLANE.png
    ./.tools/stale-conversion/BarcelonaMoto_Props_PITLANE.png.import
    ./.tools/stale-conversion/BarcelonaMoto_Props_PITLANE_NM.png
    ./.tools/stale-conversion/BarcelonaMoto_Props_PITLANE_NM.png.import
    ./.tools/stale-conversion/BarcelonaMoto_Wood_plank.png
    ./.tools/stale-conversion/BarcelonaMoto_Wood_plank.png.import
    ./.tools/stale-conversion/BarcelonaMoto_Wood_plank_MAP_rough2.png
    ./.tools/stale-conversion/BarcelonaMoto_Wood_plank_MAP_rough2.png.import
    ./.tools/stale-conversion/BarcelonaMoto_Wood_plank_NM.png
    ./.tools/stale-conversion/BarcelonaMoto_Wood_plank_NM.png.import
    ./.tools/stale-conversion/BarcelonaMoto_ac_crew.png
    ./.tools/stale-conversion/BarcelonaMoto_ac_crew.png.import
    ./.tools/stale-conversion/BarcelonaMoto_ao-ext.png
    ./.tools/stale-conversion/BarcelonaMoto_ao-ext.png.import
    ./.tools/stale-conversion/BarcelonaMoto_asd.png
    ./.tools/stale-conversion/BarcelonaMoto_asd.png.import
    ./.tools/stale-conversion/BarcelonaMoto_asph-red.png
    ./.tools/stale-conversion/BarcelonaMoto_asph-red.png.import
    ./.tools/stale-conversion/BarcelonaMoto_asph-red_MAP_rough1.png
    ./.tools/stale-conversion/BarcelonaMoto_asph-red_MAP_rough1.png.import
    ./.tools/stale-conversion/BarcelonaMoto_asph-red_MAP_rough3.png
    ./.tools/stale-conversion/BarcelonaMoto_asph-red_MAP_rough3.png.import
    ./.tools/stale-conversion/BarcelonaMoto_asph-white.png
    ./.tools/stale-conversion/BarcelonaMoto_asph-white.png.import
    ./.tools/stale-conversion/BarcelonaMoto_asph_updt.png
    ./.tools/stale-conversion/BarcelonaMoto_asph_updt.png.import
    ./.tools/stale-conversion/BarcelonaMoto_background_B.png
    ./.tools/stale-conversion/BarcelonaMoto_background_B.png.import
    ./.tools/stale-conversion/BarcelonaMoto_barcelona t10.png
    ./.tools/stale-conversion/BarcelonaMoto_barcelona t10.png.import
    ./.tools/stale-conversion/BarcelonaMoto_bark.png
    ./.tools/stale-conversion/BarcelonaMoto_bark.png.import
    ./.tools/stale-conversion/BarcelonaMoto_barrier.png
    ./.tools/stale-conversion/BarcelonaMoto_barrier.png.import
    ./.tools/stale-conversion/BarcelonaMoto_box-fence.png
    ./.tools/stale-conversion/BarcelonaMoto_box-fence.png.import
    ./.tools/stale-conversion/BarcelonaMoto_box-numbers.png
    ./.tools/stale-conversion/BarcelonaMoto_box-numbers.png.import
    ./.tools/stale-conversion/BarcelonaMoto_box-wall.png
    ./.tools/stale-conversion/BarcelonaMoto_box-wall.png.import
    ./.tools/stale-conversion/BarcelonaMoto_box-wall_MAP_rough18.png
    ./.tools/stale-conversion/BarcelonaMoto_box-wall_MAP_rough18.png.import
    ./.tools/stale-conversion/BarcelonaMoto_box-wall_NM.png
    ./.tools/stale-conversion/BarcelonaMoto_box-wall_NM.png.import
    ./.tools/stale-conversion/BarcelonaMoto_box1.png
    ./.tools/stale-conversion/BarcelonaMoto_box1.png.import
    ./.tools/stale-conversion/BarcelonaMoto_box1_MAP_rough1.png
    ./.tools/stale-conversion/BarcelonaMoto_box1_MAP_rough1.png.import
    ./.tools/stale-conversion/BarcelonaMoto_box1_MAP_rough2.png
    ./.tools/stale-conversion/BarcelonaMoto_box1_MAP_rough2.png.import
    ./.tools/stale-conversion/BarcelonaMoto_box1_MAP_rough20.png
    ./.tools/stale-conversion/BarcelonaMoto_box1_MAP_rough20.png.import
    ./.tools/stale-conversion/BarcelonaMoto_box1_MAP_rough7.png
    ./.tools/stale-conversion/BarcelonaMoto_box1_MAP_rough7.png.import
    ./.tools/stale-conversion/BarcelonaMoto_box1_NM.png
    ./.tools/stale-conversion/BarcelonaMoto_box1_NM.png.import
    ./.tools/stale-conversion/BarcelonaMoto_branch5.png
    ./.tools/stale-conversion/BarcelonaMoto_branch5.png.import
    ./.tools/stale-conversion/BarcelonaMoto_bridge2.png
    ./.tools/stale-conversion/BarcelonaMoto_bridge2.png.import
    ./.tools/stale-conversion/BarcelonaMoto_bridge2_MAP_rough5.png
    ./.tools/stale-conversion/BarcelonaMoto_bridge2_MAP_rough5.png.import
    ./.tools/stale-conversion/BarcelonaMoto_bridge2_NM.png
    ./.tools/stale-conversion/BarcelonaMoto_bridge2_NM.png.import
    ./.tools/stale-conversion/BarcelonaMoto_bridge_1B_MAP_rough1.png
    ./.tools/stale-conversion/BarcelonaMoto_bridge_1B_MAP_rough1.png.import
    ./.tools/stale-conversion/BarcelonaMoto_bridge_1B_MAP_rough4.png
    ./.tools/stale-conversion/BarcelonaMoto_bridge_1B_MAP_rough4.png.import
    ./.tools/stale-conversion/BarcelonaMoto_bridge_1_d.png
    ./.tools/stale-conversion/BarcelonaMoto_bridge_1_d.png.import
    ./.tools/stale-conversion/BarcelonaMoto_bridge_normal.png
    ./.tools/stale-conversion/BarcelonaMoto_bridge_normal.png.import
    ./.tools/stale-conversion/BarcelonaMoto_carpet-base_MAP_rough38.png
    ./.tools/stale-conversion/BarcelonaMoto_carpet-base_MAP_rough38.png.import
    ./.tools/stale-conversion/BarcelonaMoto_carpet.png
    ./.tools/stale-conversion/BarcelonaMoto_carpet.png.import
    ./.tools/stale-conversion/BarcelonaMoto_carpet_NM.png
    ./.tools/stale-conversion/BarcelonaMoto_carpet_NM.png.import
    ./.tools/stale-conversion/BarcelonaMoto_catalunya spons1.png
    ./.tools/stale-conversion/BarcelonaMoto_catalunya spons1.png.import
    ./.tools/stale-conversion/BarcelonaMoto_clockdisplay.png
    ./.tools/stale-conversion/BarcelonaMoto_clockdisplay.png.import
    ./.tools/stale-conversion/BarcelonaMoto_commissario_NEW.png
    ./.tools/stale-conversion/BarcelonaMoto_commissario_NEW.png.import
    ./.tools/stale-conversion/BarcelonaMoto_concrete_box.png
    ./.tools/stale-conversion/BarcelonaMoto_concrete_box.png.import
    ./.tools/stale-conversion/BarcelonaMoto_concrete_box_MAP_rough1.png
    ./.tools/stale-conversion/BarcelonaMoto_concrete_box_MAP_rough1.png.import
    ./.tools/stale-conversion/BarcelonaMoto_concrete_box_NM.png
    ./.tools/stale-conversion/BarcelonaMoto_concrete_box_NM.png.import
    ./.tools/stale-conversion/BarcelonaMoto_concrete_white_old_albedo2.png
    ./.tools/stale-conversion/BarcelonaMoto_concrete_white_old_albedo2.png.import
    ./.tools/stale-conversion/BarcelonaMoto_curb1_A.png
    ./.tools/stale-conversion/BarcelonaMoto_curb1_A.png.import
    ./.tools/stale-conversion/BarcelonaMoto_curb1_NM.png
    ./.tools/stale-conversion/BarcelonaMoto_curb1_NM.png.import
    ./.tools/stale-conversion/BarcelonaMoto_curb2.png
    ./.tools/stale-conversion/BarcelonaMoto_curb2.png.import
    ./.tools/stale-conversion/BarcelonaMoto_curb2_NM.png
    ./.tools/stale-conversion/BarcelonaMoto_curb2_NM.png.import
    ./.tools/stale-conversion/BarcelonaMoto_curb_typeB.png
    ./.tools/stale-conversion/BarcelonaMoto_curb_typeB.png.import
    ./.tools/stale-conversion/BarcelonaMoto_curb_typeB_NM.png
    ./.tools/stale-conversion/BarcelonaMoto_curb_typeB_NM.png.import
    ./.tools/stale-conversion/BarcelonaMoto_digitalflag.png
    ./.tools/stale-conversion/BarcelonaMoto_digitalflag.png.import
    ./.tools/stale-conversion/BarcelonaMoto_digitalflag_main_alb.png
    ./.tools/stale-conversion/BarcelonaMoto_digitalflag_main_alb.png.import
    ./.tools/stale-conversion/BarcelonaMoto_direction-villa.png
    ./.tools/stale-conversion/BarcelonaMoto_direction-villa.png.import
    ./.tools/stale-conversion/BarcelonaMoto_distanz.png
    ./.tools/stale-conversion/BarcelonaMoto_distanz.png.import
    ./.tools/stale-conversion/BarcelonaMoto_distanz_MAP_rough1.png
    ./.tools/stale-conversion/BarcelonaMoto_distanz_MAP_rough1.png.import
    ./.tools/stale-conversion/BarcelonaMoto_distanz_NM.png
    ./.tools/stale-conversion/BarcelonaMoto_distanz_NM.png.import
    ./.tools/stale-conversion/BarcelonaMoto_drs.png
    ./.tools/stale-conversion/BarcelonaMoto_drs.png.import
    ./.tools/stale-conversion/BarcelonaMoto_fences1.png
    ./.tools/stale-conversion/BarcelonaMoto_fences1.png.import
    ./.tools/stale-conversion/BarcelonaMoto_fences2.png
    ./.tools/stale-conversion/BarcelonaMoto_fences2.png.import
    ./.tools/stale-conversion/BarcelonaMoto_flat_NM.png
    ./.tools/stale-conversion/BarcelonaMoto_flat_NM.png.import
    ./.tools/stale-conversion/BarcelonaMoto_glass-box.png
    ./.tools/stale-conversion/BarcelonaMoto_glass-box.png.import
    ./.tools/stale-conversion/BarcelonaMoto_glass-name1.png
    ./.tools/stale-conversion/BarcelonaMoto_glass-name1.png.import
    ./.tools/stale-conversion/BarcelonaMoto_grail.png
    ./.tools/stale-conversion/BarcelonaMoto_grail.png.import
    ./.tools/stale-conversion/BarcelonaMoto_grail_MAP_rough60.png
    ./.tools/stale-conversion/BarcelonaMoto_grail_MAP_rough60.png.import
    ./.tools/stale-conversion/BarcelonaMoto_grail_NM.png
    ./.tools/stale-conversion/BarcelonaMoto_grail_NM.png.import
    ./.tools/stale-conversion/BarcelonaMoto_grass-brd-ext.png
    ./.tools/stale-conversion/BarcelonaMoto_grass-brd-ext.png.import
    ./.tools/stale-conversion/BarcelonaMoto_grass-brd3-F.png
    ./.tools/stale-conversion/BarcelonaMoto_grass-brd3-F.png.import
    ./.tools/stale-conversion/BarcelonaMoto_grass2_MAP_rough2.png
    ./.tools/stale-conversion/BarcelonaMoto_grass2_MAP_rough2.png.import
    ./.tools/stale-conversion/BarcelonaMoto_grass_base2.png
    ./.tools/stale-conversion/BarcelonaMoto_grass_base2.png.import
    ./.tools/stale-conversion/BarcelonaMoto_gravel.png
    ./.tools/stale-conversion/BarcelonaMoto_gravel.png.import
    ./.tools/stale-conversion/BarcelonaMoto_grille.png
    ./.tools/stale-conversion/BarcelonaMoto_grille.png.import
    ./.tools/stale-conversion/BarcelonaMoto_grille2.png
    ./.tools/stale-conversion/BarcelonaMoto_grille2.png.import
    ./.tools/stale-conversion/BarcelonaMoto_grille2_MAP_rough8.png
    ./.tools/stale-conversion/BarcelonaMoto_grille2_MAP_rough8.png.import
    ./.tools/stale-conversion/BarcelonaMoto_grille2_NM.png
    ./.tools/stale-conversion/BarcelonaMoto_grille2_NM.png.import
    ./.tools/stale-conversion/BarcelonaMoto_grille2_red.png
    ./.tools/stale-conversion/BarcelonaMoto_grille2_red.png.import
    ./.tools/stale-conversion/BarcelonaMoto_grille_MAP_rough3.png
    ./.tools/stale-conversion/BarcelonaMoto_grille_MAP_rough3.png.import
    ./.tools/stale-conversion/BarcelonaMoto_grille_NM.png
    ./.tools/stale-conversion/BarcelonaMoto_grille_NM.png.import
    ./.tools/stale-conversion/BarcelonaMoto_groove.png
    ./.tools/stale-conversion/BarcelonaMoto_groove.png.import
    ./.tools/stale-conversion/BarcelonaMoto_ground spons 2.png
    ./.tools/stale-conversion/BarcelonaMoto_ground spons 2.png.import
    ./.tools/stale-conversion/BarcelonaMoto_gstand-detail2.png
    ./.tools/stale-conversion/BarcelonaMoto_gstand-detail2.png.import
    ./.tools/stale-conversion/BarcelonaMoto_gstand-detail3.png
    ./.tools/stale-conversion/BarcelonaMoto_gstand-detail3.png.import
    ./.tools/stale-conversion/BarcelonaMoto_gstand-detail3_MAP_rough3.png
    ./.tools/stale-conversion/BarcelonaMoto_gstand-detail3_MAP_rough3.png.import
    ./.tools/stale-conversion/BarcelonaMoto_gstand-detail3_NM.png
    ./.tools/stale-conversion/BarcelonaMoto_gstand-detail3_NM.png.import
    ./.tools/stale-conversion/BarcelonaMoto_itpine_E.png
    ./.tools/stale-conversion/BarcelonaMoto_itpine_E.png.import
    ./.tools/stale-conversion/BarcelonaMoto_ivy_hi.png
    ./.tools/stale-conversion/BarcelonaMoto_ivy_hi.png.import
    ./.tools/stale-conversion/BarcelonaMoto_lapdisplay.png
    ./.tools/stale-conversion/BarcelonaMoto_lapdisplay.png.import
    ./.tools/stale-conversion/BarcelonaMoto_ledwall.png
    ./.tools/stale-conversion/BarcelonaMoto_ledwall.png.import
    ./.tools/stale-conversion/BarcelonaMoto_marshall-box.png
    ./.tools/stale-conversion/BarcelonaMoto_marshall-box.png.import
    ./.tools/stale-conversion/BarcelonaMoto_marshall-box_MAP_rough4.png
    ./.tools/stale-conversion/BarcelonaMoto_marshall-box_MAP_rough4.png.import
    ./.tools/stale-conversion/BarcelonaMoto_marshallA.png
    ./.tools/stale-conversion/BarcelonaMoto_marshallA.png.import
    ./.tools/stale-conversion/BarcelonaMoto_mid_NM.png
    ./.tools/stale-conversion/BarcelonaMoto_mid_NM.png.import
    ./.tools/stale-conversion/BarcelonaMoto_misc.png
    ./.tools/stale-conversion/BarcelonaMoto_misc.png.import
    ./.tools/stale-conversion/BarcelonaMoto_net-alpha.png
    ./.tools/stale-conversion/BarcelonaMoto_net-alpha.png.import
    ./.tools/stale-conversion/BarcelonaMoto_panels.png
    ./.tools/stale-conversion/BarcelonaMoto_panels.png.import
    ./.tools/stale-conversion/BarcelonaMoto_paratie1.png
    ./.tools/stale-conversion/BarcelonaMoto_paratie1.png.import
    ./.tools/stale-conversion/BarcelonaMoto_pine_leaf.png
    ./.tools/stale-conversion/BarcelonaMoto_pine_leaf.png.import
    ./.tools/stale-conversion/BarcelonaMoto_pitlane-build1.png
    ./.tools/stale-conversion/BarcelonaMoto_pitlane-build1.png.import
    ./.tools/stale-conversion/BarcelonaMoto_podium.png
    ./.tools/stale-conversion/BarcelonaMoto_podium.png.import
    ./.tools/stale-conversion/BarcelonaMoto_pole1.png
    ./.tools/stale-conversion/BarcelonaMoto_pole1.png.import
    ./.tools/stale-conversion/BarcelonaMoto_red-pitlane.png
    ./.tools/stale-conversion/BarcelonaMoto_red-pitlane.png.import
    ./.tools/stale-conversion/BarcelonaMoto_road-concrete-ext.png
    ./.tools/stale-conversion/BarcelonaMoto_road-concrete-ext.png.import
    ./.tools/stale-conversion/BarcelonaMoto_roof-tile_D.png
    ./.tools/stale-conversion/BarcelonaMoto_roof-tile_D.png.import
    ./.tools/stale-conversion/BarcelonaMoto_roof-tile_MAP_rough1.png
    ./.tools/stale-conversion/BarcelonaMoto_roof-tile_MAP_rough1.png.import
    ./.tools/stale-conversion/BarcelonaMoto_roof-tile_NM.png
    ./.tools/stale-conversion/BarcelonaMoto_roof-tile_NM.png.import
    ./.tools/stale-conversion/BarcelonaMoto_sand_base.png
    ./.tools/stale-conversion/BarcelonaMoto_sand_base.png.import
    ./.tools/stale-conversion/BarcelonaMoto_sand_base_MAP_rough1.png
    ./.tools/stale-conversion/BarcelonaMoto_sand_base_MAP_rough1.png.import
    ./.tools/stale-conversion/BarcelonaMoto_sand_base_NM.png
    ./.tools/stale-conversion/BarcelonaMoto_sand_base_NM.png.import
    ./.tools/stale-conversion/BarcelonaMoto_sat2B.png
    ./.tools/stale-conversion/BarcelonaMoto_sat2B.png.import
    ./.tools/stale-conversion/BarcelonaMoto_semaphore.png
    ./.tools/stale-conversion/BarcelonaMoto_semaphore.png.import
    ./.tools/stale-conversion/BarcelonaMoto_series logo.png
    ./.tools/stale-conversion/BarcelonaMoto_series logo.png.import
    ./.tools/stale-conversion/BarcelonaMoto_slow-curb.png
    ./.tools/stale-conversion/BarcelonaMoto_slow-curb.png.import
    ./.tools/stale-conversion/BarcelonaMoto_slow-curb_MAP_rough2.png
    ./.tools/stale-conversion/BarcelonaMoto_slow-curb_MAP_rough2.png.import
    ./.tools/stale-conversion/BarcelonaMoto_slow-curb_NM.png
    ./.tools/stale-conversion/BarcelonaMoto_slow-curb_NM.png.import
    ./.tools/stale-conversion/BarcelonaMoto_sp_bumps.png
    ./.tools/stale-conversion/BarcelonaMoto_sp_bumps.png.import
    ./.tools/stale-conversion/BarcelonaMoto_sponsors 2.png
    ./.tools/stale-conversion/BarcelonaMoto_sponsors 2.png.import
    ./.tools/stale-conversion/BarcelonaMoto_sponsors-ground1.png
    ./.tools/stale-conversion/BarcelonaMoto_sponsors-ground1.png.import
    ./.tools/stale-conversion/BarcelonaMoto_sponsors.png
    ./.tools/stale-conversion/BarcelonaMoto_sponsors.png.import
    ./.tools/stale-conversion/BarcelonaMoto_struc-green-ext.png
    ./.tools/stale-conversion/BarcelonaMoto_struc-green-ext.png.import
    ./.tools/stale-conversion/BarcelonaMoto_structures-alpha.png
    ./.tools/stale-conversion/BarcelonaMoto_structures-alpha.png.import
    ./.tools/stale-conversion/BarcelonaMoto_structures-base.png
    ./.tools/stale-conversion/BarcelonaMoto_structures-base.png.import
    ./.tools/stale-conversion/BarcelonaMoto_structures-base_MAP_rough2.png
    ./.tools/stale-conversion/BarcelonaMoto_structures-base_MAP_rough2.png.import
    ./.tools/stale-conversion/BarcelonaMoto_tarmac_green.png
    ./.tools/stale-conversion/BarcelonaMoto_tarmac_green.png.import
    ./.tools/stale-conversion/BarcelonaMoto_tent-fabric1.png
    ./.tools/stale-conversion/BarcelonaMoto_tent-fabric1.png.import
    ./.tools/stale-conversion/BarcelonaMoto_time-tower.png
    ./.tools/stale-conversion/BarcelonaMoto_time-tower.png.import
    ./.tools/stale-conversion/BarcelonaMoto_tower spons.png
    ./.tools/stale-conversion/BarcelonaMoto_tower spons.png.import
    ./.tools/stale-conversion/BarcelonaMoto_towerdisplay.png
    ./.tools/stale-conversion/BarcelonaMoto_towerdisplay.png.import
    ./.tools/stale-conversion/BarcelonaMoto_tree_shadow.png
    ./.tools/stale-conversion/BarcelonaMoto_tree_shadow.png.import
    ./.tools/stale-conversion/BarcelonaMoto_trees2G.png
    ./.tools/stale-conversion/BarcelonaMoto_trees2G.png.import
    ./.tools/stale-conversion/BarcelonaMoto_tyres_add2.png
    ./.tools/stale-conversion/BarcelonaMoto_tyres_add2.png.import
    ./.tools/stale-conversion/BarcelonaMoto_walls1.png
    ./.tools/stale-conversion/BarcelonaMoto_walls1.png.import
    ./.tools/stale-conversion/BarcelonaMoto_walls1_MAP_rough2.png
    ./.tools/stale-conversion/BarcelonaMoto_walls1_MAP_rough2.png.import
    ./.tools/stale-conversion/BarcelonaMoto_walls1_NM.png
    ./.tools/stale-conversion/BarcelonaMoto_walls1_NM.png.import
    ./.tools/stale-conversion/BarcelonaMoto_whiteline.png
    ./.tools/stale-conversion/BarcelonaMoto_whiteline.png.import
    ./.tools/stale-conversion/BarcelonaMoto_whiteline3.png
    ./.tools/stale-conversion/BarcelonaMoto_whiteline3.png.import
    ./.tools/stale-conversion/BarcelonaMoto_whiteline4.png
    ./.tools/stale-conversion/BarcelonaMoto_whiteline4.png.import
    ./.tools/track-convert/barcelona-catalunya-moto.glb
    ./.tools/track-convert/barcelona-catalunya-moto.surfaces.json
    ./.tools/track-convert/barcelona-moto-optimized.glb
    ./.tools/track-convert/conversion.log
    ./.tools/track-convert/variant/barcelona-chicane-physics.glb
    ./.tools/track-convert/variant/barcelona-chicane.glb
    ./.tools/track-convert/variant/barcelona-moto-physics.glb
    ./.tools/track-convert/variant/barcelona-moto.glb
    ./.tools/track-convert/variant/chicane-physics.log
    ./.tools/track-convert/variant/chicane.log
    ./.tools/track-convert/variant/moto-physics.log
    ./.tools/track-convert/variant/moto.log
    ./.tools/tutorial-conversion/barcelona-direct-converter-original.glb
    ./.tools/tutorial-conversion/blender/barcelona-moto-joined.blend
    ./.tools/tutorial-conversion/blender/barcelona-moto-joined.blend1
    ./.tools/tutorial-conversion/blender/barcelona-moto-visual.glb
    ./.tools/tutorial-conversion/blender/check_png_export.py
    ./.tools/tutorial-conversion/blender/import_obj.py
    ./.tools/tutorial-conversion/blender/pack_textures.py
    ./.tools/tutorial-conversion/blender/texture/3dt3B.dds
    ./.tools/tutorial-conversion/blender/texture/Barcellona_Box_A.dds
    ./.tools/tutorial-conversion/blender/texture/BricksWall.dds
    ./.tools/tutorial-conversion/blender/texture/BricksWall_NM.dds
    ./.tools/tutorial-conversion/blender/texture/Concrete_detail.dds
    ./.tools/tutorial-conversion/blender/texture/Concrete_detail_3.dds
    ./.tools/tutorial-conversion/blender/texture/Concrete_detail_4.dds
    ./.tools/tutorial-conversion/blender/texture/Concrete_wall.dds
    ./.tools/tutorial-conversion/blender/texture/DRIVER_Face.dds
    ./.tools/tutorial-conversion/blender/texture/DRIVER_Suit.dds
    ./.tools/tutorial-conversion/blender/texture/Garage_Colour.dds
    ./.tools/tutorial-conversion/blender/texture/GrandStand_base.dds
    ./.tools/tutorial-conversion/blender/texture/GrandStand_base_NMW5.dds
    ./.tools/tutorial-conversion/blender/texture/Grass0151_A.dds
    ./.tools/tutorial-conversion/blender/texture/Lights_Emissive_DIF.dds
    ./.tools/tutorial-conversion/blender/texture/NULL.dds
    ./.tools/tutorial-conversion/blender/texture/Props_PITLANE.dds
    ./.tools/tutorial-conversion/blender/texture/Props_PITLANE_NM.dds
    ./.tools/tutorial-conversion/blender/texture/Rust-detail1.dds
    ./.tools/tutorial-conversion/blender/texture/Wood_plank.dds
    ./.tools/tutorial-conversion/blender/texture/Wood_plank_NM.dds
    ./.tools/tutorial-conversion/blender/texture/ac_crew.dds
    ./.tools/tutorial-conversion/blender/texture/ao-ext.dds
    ./.tools/tutorial-conversion/blender/texture/asd.dds
    ./.tools/tutorial-conversion/blender/texture/asph-red.dds
    ./.tools/tutorial-conversion/blender/texture/asph-white.dds
    ./.tools/tutorial-conversion/blender/texture/asph8_2048.dds
    ./.tools/tutorial-conversion/blender/texture/asph_updt.dds
    ./.tools/tutorial-conversion/blender/texture/background_B.dds
    ./.tools/tutorial-conversion/blender/texture/barcelona t10.dds
    ./.tools/tutorial-conversion/blender/texture/bark.dds
    ./.tools/tutorial-conversion/blender/texture/barrier.dds
    ./.tools/tutorial-conversion/blender/texture/black.dds
    ./.tools/tutorial-conversion/blender/texture/box-fence.dds
    ./.tools/tutorial-conversion/blender/texture/box-numbers.dds
    ./.tools/tutorial-conversion/blender/texture/box-wall.dds
    ./.tools/tutorial-conversion/blender/texture/box-wall_NM.dds
    ./.tools/tutorial-conversion/blender/texture/box1.dds
    ./.tools/tutorial-conversion/blender/texture/box1_NM.dds
    ./.tools/tutorial-conversion/blender/texture/branch5.dds
    ./.tools/tutorial-conversion/blender/texture/bridge2.dds
    ./.tools/tutorial-conversion/blender/texture/bridge2_NM.dds
    ./.tools/tutorial-conversion/blender/texture/bridge_1_d.dds
    ./.tools/tutorial-conversion/blender/texture/bridge_normal.dds
    ./.tools/tutorial-conversion/blender/texture/carpet.dds
    ./.tools/tutorial-conversion/blender/texture/carpet_NM.dds
    ./.tools/tutorial-conversion/blender/texture/catalunya spons1.dds
    ./.tools/tutorial-conversion/blender/texture/clockdisplay.dds
    ./.tools/tutorial-conversion/blender/texture/commissario_NEW.dds
    ./.tools/tutorial-conversion/blender/texture/concrete_box.dds
    ./.tools/tutorial-conversion/blender/texture/concrete_box_NM.dds
    ./.tools/tutorial-conversion/blender/texture/concrete_white_old_albedo2.dds
    ./.tools/tutorial-conversion/blender/texture/curb1_A.dds
    ./.tools/tutorial-conversion/blender/texture/curb1_NM.dds
    ./.tools/tutorial-conversion/blender/texture/curb2.dds
    ./.tools/tutorial-conversion/blender/texture/curb2_NM.dds
    ./.tools/tutorial-conversion/blender/texture/curb_typeB.dds
    ./.tools/tutorial-conversion/blender/texture/curb_typeB_NM.dds
    ./.tools/tutorial-conversion/blender/texture/digitalflag.dds
    ./.tools/tutorial-conversion/blender/texture/digitalflag_main_alb.dds
    ./.tools/tutorial-conversion/blender/texture/direction-villa.dds
    ./.tools/tutorial-conversion/blender/texture/distanz.dds
    ./.tools/tutorial-conversion/blender/texture/distanz_NM.dds
    ./.tools/tutorial-conversion/blender/texture/drs.dds
    ./.tools/tutorial-conversion/blender/texture/fences1.dds
    ./.tools/tutorial-conversion/blender/texture/fences2.dds
    ./.tools/tutorial-conversion/blender/texture/flat_NM.dds
    ./.tools/tutorial-conversion/blender/texture/glass-box.dds
    ./.tools/tutorial-conversion/blender/texture/glass-name1.dds
    ./.tools/tutorial-conversion/blender/texture/grail.dds
    ./.tools/tutorial-conversion/blender/texture/grail_NM.dds
    ./.tools/tutorial-conversion/blender/texture/grass-brd-ext.dds
    ./.tools/tutorial-conversion/blender/texture/grass-brd3-F.dds
    ./.tools/tutorial-conversion/blender/texture/grass_base2.dds
    ./.tools/tutorial-conversion/blender/texture/gravel.dds
    ./.tools/tutorial-conversion/blender/texture/grille.dds
    ./.tools/tutorial-conversion/blender/texture/grille2.dds
    ./.tools/tutorial-conversion/blender/texture/grille2_NM.dds
    ./.tools/tutorial-conversion/blender/texture/grille2_red.dds
    ./.tools/tutorial-conversion/blender/texture/grille_NM.dds
    ./.tools/tutorial-conversion/blender/texture/groove.dds
    ./.tools/tutorial-conversion/blender/texture/ground spons 2.dds
    ./.tools/tutorial-conversion/blender/texture/gstand-detail2.dds
    ./.tools/tutorial-conversion/blender/texture/gstand-detail3.dds
    ./.tools/tutorial-conversion/blender/texture/gstand-detail3_NM.dds
    ./.tools/tutorial-conversion/blender/texture/itpine_E.dds
    ./.tools/tutorial-conversion/blender/texture/ivy_hi.dds
    ./.tools/tutorial-conversion/blender/texture/lapdisplay.dds
    ./.tools/tutorial-conversion/blender/texture/ledwall.dds
    ./.tools/tutorial-conversion/blender/texture/marshall-box.dds
    ./.tools/tutorial-conversion/blender/texture/marshallA.dds
    ./.tools/tutorial-conversion/blender/texture/metal_dt_1.dds
    ./.tools/tutorial-conversion/blender/texture/metal_plate_roof.dds
    ./.tools/tutorial-conversion/blender/texture/metal_plate_tile_1.dds
    ./.tools/tutorial-conversion/blender/texture/mid_NM.dds
    ./.tools/tutorial-conversion/blender/texture/misc.dds
    ./.tools/tutorial-conversion/blender/texture/net-alpha.dds
    ./.tools/tutorial-conversion/blender/texture/panels.dds
    ./.tools/tutorial-conversion/blender/texture/paratie1.dds
    ./.tools/tutorial-conversion/blender/texture/pine_leaf.dds
    ./.tools/tutorial-conversion/blender/texture/pitlane-build1.dds
    ./.tools/tutorial-conversion/blender/texture/podium.dds
    ./.tools/tutorial-conversion/blender/texture/pole1.dds
    ./.tools/tutorial-conversion/blender/texture/red-pitlane.dds
    ./.tools/tutorial-conversion/blender/texture/red.dds
    ./.tools/tutorial-conversion/blender/texture/road-concrete-ext.dds
    ./.tools/tutorial-conversion/blender/texture/roof-tile_D.dds
    ./.tools/tutorial-conversion/blender/texture/roof-tile_NM.dds
    ./.tools/tutorial-conversion/blender/texture/sand_base.dds
    ./.tools/tutorial-conversion/blender/texture/sand_base_NM.dds
    ./.tools/tutorial-conversion/blender/texture/sat2B.dds
    ./.tools/tutorial-conversion/blender/texture/semaphore.dds
    ./.tools/tutorial-conversion/blender/texture/series logo.dds
    ./.tools/tutorial-conversion/blender/texture/slow-curb.dds
    ./.tools/tutorial-conversion/blender/texture/slow-curb_NM.dds
    ./.tools/tutorial-conversion/blender/texture/sp_bumps.png
    ./.tools/tutorial-conversion/blender/texture/sponsors 2.dds
    ./.tools/tutorial-conversion/blender/texture/sponsors-ground1.dds
    ./.tools/tutorial-conversion/blender/texture/sponsors.dds
    ./.tools/tutorial-conversion/blender/texture/struc-green-ext.dds
    ./.tools/tutorial-conversion/blender/texture/structures-alpha.dds
    ./.tools/tutorial-conversion/blender/texture/structures-base.dds
    ./.tools/tutorial-conversion/blender/texture/stucco_1.dds
    ./.tools/tutorial-conversion/blender/texture/tarmac_green.dds
    ./.tools/tutorial-conversion/blender/texture/tent-fabric1.dds
    ./.tools/tutorial-conversion/blender/texture/time-tower.dds
    ./.tools/tutorial-conversion/blender/texture/tower spons.dds
    ./.tools/tutorial-conversion/blender/texture/towerdisplay.dds
    ./.tools/tutorial-conversion/blender/texture/trap_detail.dds
    ./.tools/tutorial-conversion/blender/texture/tree_shadow.dds
    ./.tools/tutorial-conversion/blender/texture/trees2G.dds
    ./.tools/tutorial-conversion/blender/texture/tyres_add2.dds
    ./.tools/tutorial-conversion/blender/texture/walls1.dds
    ./.tools/tutorial-conversion/blender/texture/walls1_NM.dds
    ./.tools/tutorial-conversion/blender/texture/whiteline.dds
    ./.tools/tutorial-conversion/blender/texture/whiteline3.dds
    ./.tools/tutorial-conversion/blender/texture/whiteline4.dds
    ./.tools/tutorial-conversion/input/100.kn5
    ./.tools/tutorial-conversion/input/4.kn5
    ./.tools/tutorial-conversion/input/8.kn5
    ./.tools/tutorial-conversion/input/9.kn5
    ./.tools/tutorial-conversion/input/barcelona_2023_5.kn5
    ./.tools/tutorial-conversion/input/barcelona_remastered.kn5
    ./.tools/tutorial-conversion/input/barcelona_remastered_moto.kn5
    ./.tools/tutorial-conversion/input/barcelona_remastered_moto.mtl
    ./.tools/tutorial-conversion/input/barcelona_remastered_moto.obj
    ./.tools/tutorial-conversion/input/barcelona_remastered_physics.kn5
    ./.tools/tutorial-conversion/input/barcelona_remastered_physics_moto.kn5
    ./.tools/tutorial-conversion/input/models_barcelona_2023.ini
    ./.tools/tutorial-conversion/input/surfaces.ini
    ./.tools/tutorial-conversion/input/texture/3dt3B.dds
    ./.tools/tutorial-conversion/input/texture/Asphalt2_1024_A.dds
    ./.tools/tutorial-conversion/input/texture/Asphalt2_1024_A.png
    ./.tools/tutorial-conversion/input/texture/Asphalt2_1024_MAP.dds
    ./.tools/tutorial-conversion/input/texture/Asphalt2_1024_MAP.png
    ./.tools/tutorial-conversion/input/texture/Asphalt2_1024_NM.dds
    ./.tools/tutorial-conversion/input/texture/Asphalt2_1024_NM.png
    ./.tools/tutorial-conversion/input/texture/Asphalt4_4096_A.dds
    ./.tools/tutorial-conversion/input/texture/Asphalt7_4x4_A.dds
    ./.tools/tutorial-conversion/input/texture/Asphalt7_4x4_NMl.dds
    ./.tools/tutorial-conversion/input/texture/BBGRASS_D.dds
    ./.tools/tutorial-conversion/input/texture/Baloon_NM.dds
    ./.tools/tutorial-conversion/input/texture/Barcellona_Box_A.dds
    ./.tools/tutorial-conversion/input/texture/Barcellona_Box_A.png
    ./.tools/tutorial-conversion/input/texture/Barcellona_Box_MASK.dds
    ./.tools/tutorial-conversion/input/texture/Barcellona_Box_MASK.png
    ./.tools/tutorial-conversion/input/texture/Barcellona_Box_NM.dds
    ./.tools/tutorial-conversion/input/texture/Barcellona_Box_NM.png
    ./.tools/tutorial-conversion/input/texture/BoxAO.hdr
    ./.tools/tutorial-conversion/input/texture/Brick.dds
    ./.tools/tutorial-conversion/input/texture/Brick_MAP.dds
    ./.tools/tutorial-conversion/input/texture/Brick_NM.dds
    ./.tools/tutorial-conversion/input/texture/Brick_tile.dds
    ./.tools/tutorial-conversion/input/texture/BricksWall.dds
    ./.tools/tutorial-conversion/input/texture/BricksWall_MAP.dds
    ./.tools/tutorial-conversion/input/texture/BricksWall_NM.dds
    ./.tools/tutorial-conversion/input/texture/Concrete_detail.dds
    ./.tools/tutorial-conversion/input/texture/Concrete_detail_3.dds
    ./.tools/tutorial-conversion/input/texture/Concrete_detail_3_NM.dds
    ./.tools/tutorial-conversion/input/texture/Concrete_detail_4.dds
    ./.tools/tutorial-conversion/input/texture/Concrete_detail_NM.dds
    ./.tools/tutorial-conversion/input/texture/Concrete_wall.dds
    ./.tools/tutorial-conversion/input/texture/DRIVER_Face.dds
    ./.tools/tutorial-conversion/input/texture/DRIVER_Suit.dds
    ./.tools/tutorial-conversion/input/texture/Decal1.dds
    ./.tools/tutorial-conversion/input/texture/Decal1.png
    ./.tools/tutorial-conversion/input/texture/Garage_Colour.dds
    ./.tools/tutorial-conversion/input/texture/GrandStand_base.dds
    ./.tools/tutorial-conversion/input/texture/GrandStand_base_MAP.dds
    ./.tools/tutorial-conversion/input/texture/GrandStand_base_NMW5.dds
    ./.tools/tutorial-conversion/input/texture/GrandStand_orig001NormalsMap.dds
    ./.tools/tutorial-conversion/input/texture/GrandStand_orig001NormalsMap.png
    ./.tools/tutorial-conversion/input/texture/Grass0151_A.dds
    ./.tools/tutorial-conversion/input/texture/Lights_Emissive_DIF.dds
    ./.tools/tutorial-conversion/input/texture/Lights_Emissive_DIF.png
    ./.tools/tutorial-conversion/input/texture/Lights_Emissive_NM.dds
    ./.tools/tutorial-conversion/input/texture/Lights_Emissive_NM.png
    ./.tools/tutorial-conversion/input/texture/Mask-RED.dds
    ./.tools/tutorial-conversion/input/texture/NULL.dds
    ./.tools/tutorial-conversion/input/texture/Props_PITLANE.dds
    ./.tools/tutorial-conversion/input/texture/Props_PITLANE_NM.dds
    ./.tools/tutorial-conversion/input/texture/Roof4.dds
    ./.tools/tutorial-conversion/input/texture/Roof4.png
    ./.tools/tutorial-conversion/input/texture/Roof4_NM.dds
    ./.tools/tutorial-conversion/input/texture/Roof4_NM.png
    ./.tools/tutorial-conversion/input/texture/Rust-detail1.dds
    ./.tools/tutorial-conversion/input/texture/SAND-02-500cm_Color-4k.dds
    ./.tools/tutorial-conversion/input/texture/TilesSmall.dds
    ./.tools/tutorial-conversion/input/texture/TilesSmall_A.dds
    ./.tools/tutorial-conversion/input/texture/TilesSmall_A.png
    ./.tools/tutorial-conversion/input/texture/TilesSmall_NM.dds
    ./.tools/tutorial-conversion/input/texture/TilesSmall_NM.png
    ./.tools/tutorial-conversion/input/texture/Vehicles_D.dds
    ./.tools/tutorial-conversion/input/texture/Wood_plank.dds
    ./.tools/tutorial-conversion/input/texture/Wood_plank_MAP.dds
    ./.tools/tutorial-conversion/input/texture/Wood_plank_NM.dds
    ./.tools/tutorial-conversion/input/texture/ac_crew.dds
    ./.tools/tutorial-conversion/input/texture/amb.dds
    ./.tools/tutorial-conversion/input/texture/amb_map.dds
    ./.tools/tutorial-conversion/input/texture/ao-ext.dds
    ./.tools/tutorial-conversion/input/texture/ao-ext_MAP.dds
    ./.tools/tutorial-conversion/input/texture/ao-ext_MAP.png
    ./.tools/tutorial-conversion/input/texture/asd.dds
    ./.tools/tutorial-conversion/input/texture/asph-green-b.dds
    ./.tools/tutorial-conversion/input/texture/asph-paint-detail.dds
    ./.tools/tutorial-conversion/input/texture/asph-paint-detail2.dds
    ./.tools/tutorial-conversion/input/texture/asph-paint-detail2_NM.dds
    ./.tools/tutorial-conversion/input/texture/asph-paint-detail_NM.dds
    ./.tools/tutorial-conversion/input/texture/asph-pitlane-t.dds
    ./.tools/tutorial-conversion/input/texture/asph-red.dds
    ./.tools/tutorial-conversion/input/texture/asph-red_MAP.dds
    ./.tools/tutorial-conversion/input/texture/asph-white.dds
    ./.tools/tutorial-conversion/input/texture/asph4.dds
    ./.tools/tutorial-conversion/input/texture/asph4_MAP.dds
    ./.tools/tutorial-conversion/input/texture/asph4_MASK.dds
    ./.tools/tutorial-conversion/input/texture/asph8_2048.dds
    ./.tools/tutorial-conversion/input/texture/asph8_NM.dds
    ./.tools/tutorial-conversion/input/texture/asph_updt.dds
    ./.tools/tutorial-conversion/input/texture/background_B.dds
    ./.tools/tutorial-conversion/input/texture/background_B.png
    ./.tools/tutorial-conversion/input/texture/background_B_emissive.dds
    ./.tools/tutorial-conversion/input/texture/background_B_emissive.png
    ./.tools/tutorial-conversion/input/texture/baloon.dds
    ./.tools/tutorial-conversion/input/texture/baloon1.dds
    ./.tools/tutorial-conversion/input/texture/barcelona t10.dds
    ./.tools/tutorial-conversion/input/texture/bark.dds
    ./.tools/tutorial-conversion/input/texture/bark_MAP.dds
    ./.tools/tutorial-conversion/input/texture/bark_NM.dds
    ./.tools/tutorial-conversion/input/texture/barrier-b.dds
    ./.tools/tutorial-conversion/input/texture/barrier.dds
    ./.tools/tutorial-conversion/input/texture/barrier.png
    ./.tools/tutorial-conversion/input/texture/barrier_MAP.dds
    ./.tools/tutorial-conversion/input/texture/barrier_NM-b.dds
    ./.tools/tutorial-conversion/input/texture/barrier_NM.dds
    ./.tools/tutorial-conversion/input/texture/barrier_NM.png
    ./.tools/tutorial-conversion/input/texture/barrier_rough.dds
    ./.tools/tutorial-conversion/input/texture/barrier_rough.png
    ./.tools/tutorial-conversion/input/texture/barriers-B.dds
    ./.tools/tutorial-conversion/input/texture/barriers-B.png
    ./.tools/tutorial-conversion/input/texture/barriers-B_MAP.dds
    ./.tools/tutorial-conversion/input/texture/barriers-B_MAP.png
    ./.tools/tutorial-conversion/input/texture/barriers-B_NM.dds
    ./.tools/tutorial-conversion/input/texture/barriers-B_NM.png
    ./.tools/tutorial-conversion/input/texture/black.dds
    ./.tools/tutorial-conversion/input/texture/box-fence.dds
    ./.tools/tutorial-conversion/input/texture/box-fence.png
    ./.tools/tutorial-conversion/input/texture/box-fence_NM.dds
    ./.tools/tutorial-conversion/input/texture/box-fence_NM.png
    ./.tools/tutorial-conversion/input/texture/box-numbers.dds
    ./.tools/tutorial-conversion/input/texture/box-numbers.png
    ./.tools/tutorial-conversion/input/texture/box-wall.dds
    ./.tools/tutorial-conversion/input/texture/box-wall.png
    ./.tools/tutorial-conversion/input/texture/box-wall_MAP.dds
    ./.tools/tutorial-conversion/input/texture/box-wall_NM.dds
    ./.tools/tutorial-conversion/input/texture/box-wall_NM.png
    ./.tools/tutorial-conversion/input/texture/box-wall_mask_metallic.dds
    ./.tools/tutorial-conversion/input/texture/box-wall_mask_metallic.png
    ./.tools/tutorial-conversion/input/texture/box-wall_wetmask.dds
    ./.tools/tutorial-conversion/input/texture/box-wall_wetmask.png
    ./.tools/tutorial-conversion/input/texture/box1.dds
    ./.tools/tutorial-conversion/input/texture/box1.png
    ./.tools/tutorial-conversion/input/texture/box1_MAP.dds
    ./.tools/tutorial-conversion/input/texture/box1_MAP.png
    ./.tools/tutorial-conversion/input/texture/box1_MASK.dds
    ./.tools/tutorial-conversion/input/texture/box1_NM.dds
    ./.tools/tutorial-conversion/input/texture/box1_emissive.dds
    ./.tools/tutorial-conversion/input/texture/box1_emissive.png
    ./.tools/tutorial-conversion/input/texture/box1_mask.png
    ./.tools/tutorial-conversion/input/texture/branch5.dds
    ./.tools/tutorial-conversion/input/texture/brd.dds
    ./.tools/tutorial-conversion/input/texture/bridge2.dds
    ./.tools/tutorial-conversion/input/texture/bridge2.png
    ./.tools/tutorial-conversion/input/texture/bridge2_MAP.dds
    ./.tools/tutorial-conversion/input/texture/bridge2_MAP.png
    ./.tools/tutorial-conversion/input/texture/bridge2_NM.dds
    ./.tools/tutorial-conversion/input/texture/bridge_1B_MAP.dds
    ./.tools/tutorial-conversion/input/texture/bridge_1B_MAP.png
    ./.tools/tutorial-conversion/input/texture/bridge_1B_d.dds
    ./.tools/tutorial-conversion/input/texture/bridge_1B_d.png
    ./.tools/tutorial-conversion/input/texture/bridge_1_d.dds
    ./.tools/tutorial-conversion/input/texture/bridge_2_NM.dds
    ./.tools/tutorial-conversion/input/texture/bridge_2_NM.png
    ./.tools/tutorial-conversion/input/texture/bridge_normal.dds
    ./.tools/tutorial-conversion/input/texture/bridge_normal.png
    ./.tools/tutorial-conversion/input/texture/bridges.dds
    ./.tools/tutorial-conversion/input/texture/bridges.png
    ./.tools/tutorial-conversion/input/texture/bridges_NM.dds
    ./.tools/tutorial-conversion/input/texture/bridges_NM.png
    ./.tools/tutorial-conversion/input/texture/carpet-base.dds
    ./.tools/tutorial-conversion/input/texture/carpet-base_MAP.dds
    ./.tools/tutorial-conversion/input/texture/carpet-base_NM.dds
    ./.tools/tutorial-conversion/input/texture/carpet.dds
    ./.tools/tutorial-conversion/input/texture/carpet.png
    ./.tools/tutorial-conversion/input/texture/carpet_MAP.dds
    ./.tools/tutorial-conversion/input/texture/carpet_MAP.png
    ./.tools/tutorial-conversion/input/texture/carpet_NM.dds
    ./.tools/tutorial-conversion/input/texture/carpet_NM.png
    ./.tools/tutorial-conversion/input/texture/carpet_height.dds
    ./.tools/tutorial-conversion/input/texture/carpet_height.png
    ./.tools/tutorial-conversion/input/texture/carpet_wetmask.dds
    ./.tools/tutorial-conversion/input/texture/carpet_wetmask.png
    ./.tools/tutorial-conversion/input/texture/catalunya spons1.dds
    ./.tools/tutorial-conversion/input/texture/clockdisplay.dds
    ./.tools/tutorial-conversion/input/texture/cloud.dds
    ./.tools/tutorial-conversion/input/texture/commissario_NEW.dds
    ./.tools/tutorial-conversion/input/texture/concrete_box.dds
    ./.tools/tutorial-conversion/input/texture/concrete_box.png
    ./.tools/tutorial-conversion/input/texture/concrete_box_MAP.dds
    ./.tools/tutorial-conversion/input/texture/concrete_box_NM.dds
    ./.tools/tutorial-conversion/input/texture/concrete_green.dds
    ./.tools/tutorial-conversion/input/texture/concrete_tile.dds
    ./.tools/tutorial-conversion/input/texture/concrete_tile.png
    ./.tools/tutorial-conversion/input/texture/concrete_tile_NM.dds
    ./.tools/tutorial-conversion/input/texture/concrete_tile_NM.png
    ./.tools/tutorial-conversion/input/texture/concrete_white_old_albedo2.dds
    ./.tools/tutorial-conversion/input/texture/curb1_A.dds
    ./.tools/tutorial-conversion/input/texture/curb1_A.png
    ./.tools/tutorial-conversion/input/texture/curb1_MAP.dds
    ./.tools/tutorial-conversion/input/texture/curb1_NM.dds
    ./.tools/tutorial-conversion/input/texture/curb1_NM.png
    ./.tools/tutorial-conversion/input/texture/curb1_albedo.dds
    ./.tools/tutorial-conversion/input/texture/curb1_wetmask.dds
    ./.tools/tutorial-conversion/input/texture/curb1_wetmask.png
    ./.tools/tutorial-conversion/input/texture/curb2.dds
    ./.tools/tutorial-conversion/input/texture/curb2.png
    ./.tools/tutorial-conversion/input/texture/curb2_MAP.dds
    ./.tools/tutorial-conversion/input/texture/curb2_NM.dds
    ./.tools/tutorial-conversion/input/texture/curb2_NM.png
    ./.tools/tutorial-conversion/input/texture/curb2_albedo.dds
    ./.tools/tutorial-conversion/input/texture/curb2_wetmask.dds
    ./.tools/tutorial-conversion/input/texture/curb2_wetmask.png
    ./.tools/tutorial-conversion/input/texture/curb_typeB.dds
    ./.tools/tutorial-conversion/input/texture/curb_typeB.png
    ./.tools/tutorial-conversion/input/texture/curb_typeB_NM.dds
    ./.tools/tutorial-conversion/input/texture/curb_typeB_NM.png
    ./.tools/tutorial-conversion/input/texture/curb_typeB_wetmask.dds
    ./.tools/tutorial-conversion/input/texture/curb_typeB_wetmask.png
    ./.tools/tutorial-conversion/input/texture/decal2.dds
    ./.tools/tutorial-conversion/input/texture/decal2.png
    ./.tools/tutorial-conversion/input/texture/digitalflag.dds
    ./.tools/tutorial-conversion/input/texture/digitalflag_main_alb.dds
    ./.tools/tutorial-conversion/input/texture/direction-villa.dds
    ./.tools/tutorial-conversion/input/texture/direction-villa_Albedo.dds
    ./.tools/tutorial-conversion/input/texture/direction-villa_Albedo.png
    ./.tools/tutorial-conversion/input/texture/direction-villa_MAP.dds
    ./.tools/tutorial-conversion/input/texture/direction-villa_MAP.png
    ./.tools/tutorial-conversion/input/texture/direction-villa_MASK.dds
    ./.tools/tutorial-conversion/input/texture/direction-villa_MASK.png
    ./.tools/tutorial-conversion/input/texture/dirt1.dds
    ./.tools/tutorial-conversion/input/texture/distanz.dds
    ./.tools/tutorial-conversion/input/texture/distanz.png
    ./.tools/tutorial-conversion/input/texture/distanz_MAP.dds
    ./.tools/tutorial-conversion/input/texture/distanz_MAP.png
    ./.tools/tutorial-conversion/input/texture/distanz_NM.dds
    ./.tools/tutorial-conversion/input/texture/distanz_NM.png
    ./.tools/tutorial-conversion/input/texture/drs.dds
    ./.tools/tutorial-conversion/input/texture/fences1.dds
    ./.tools/tutorial-conversion/input/texture/fences1.png
    ./.tools/tutorial-conversion/input/texture/fences2.dds
    ./.tools/tutorial-conversion/input/texture/fences2.png
    ./.tools/tutorial-conversion/input/texture/fences3.dds
    ./.tools/tutorial-conversion/input/texture/flat_NM.dds
    ./.tools/tutorial-conversion/input/texture/glass-box.dds
    ./.tools/tutorial-conversion/input/texture/glass-box.png
    ./.tools/tutorial-conversion/input/texture/glass-box_MAP.dds
    ./.tools/tutorial-conversion/input/texture/glass-box_MAP.png
    ./.tools/tutorial-conversion/input/texture/glass-name1.dds
    ./.tools/tutorial-conversion/input/texture/grail.dds
    ./.tools/tutorial-conversion/input/texture/grail.png
    ./.tools/tutorial-conversion/input/texture/grail_MAP.dds
    ./.tools/tutorial-conversion/input/texture/grail_MAP.png
    ./.tools/tutorial-conversion/input/texture/grail_NM.dds
    ./.tools/tutorial-conversion/input/texture/grail_NM.png
    ./.tools/tutorial-conversion/input/texture/grass-base2.dds
    ./.tools/tutorial-conversion/input/texture/grass-brd-ext.dds
    ./.tools/tutorial-conversion/input/texture/grass-brd-ext.png
    ./.tools/tutorial-conversion/input/texture/grass-brd-ext_NM.dds
    ./.tools/tutorial-conversion/input/texture/grass-brd-ext_NM.png
    ./.tools/tutorial-conversion/input/texture/grass-brd3-F.dds
    ./.tools/tutorial-conversion/input/texture/grass-brd3-F.png
    ./.tools/tutorial-conversion/input/texture/grass-brd3-F_MASK.dds
    ./.tools/tutorial-conversion/input/texture/grass-brd3-F_MASK.png
    ./.tools/tutorial-conversion/input/texture/grass2_MAP.dds
    ./.tools/tutorial-conversion/input/texture/grass3Eb.dds
    ./.tools/tutorial-conversion/input/texture/grass_NM_3_low.dds
    ./.tools/tutorial-conversion/input/texture/grass_base2.dds
    ./.tools/tutorial-conversion/input/texture/grass_overlay.png
    ./.tools/tutorial-conversion/input/texture/grass_var2.dds
    ./.tools/tutorial-conversion/input/texture/gravel.dds
    ./.tools/tutorial-conversion/input/texture/gravel.png
    ./.tools/tutorial-conversion/input/texture/gravelExt_mask.dds
    ./.tools/tutorial-conversion/input/texture/gravelExt_mask.png
    ./.tools/tutorial-conversion/input/texture/gravel_NM.dds
    ./.tools/tutorial-conversion/input/texture/gravel_NM.png
    ./.tools/tutorial-conversion/input/texture/gravel_ext.dds
    ./.tools/tutorial-conversion/input/texture/gravel_ext.png
    ./.tools/tutorial-conversion/input/texture/gravel_mask.dds
    ./.tools/tutorial-conversion/input/texture/gravel_mask.png
    ./.tools/tutorial-conversion/input/texture/grille.dds
    ./.tools/tutorial-conversion/input/texture/grille.png
    ./.tools/tutorial-conversion/input/texture/grille1.dds
    ./.tools/tutorial-conversion/input/texture/grille1.png
    ./.tools/tutorial-conversion/input/texture/grille1_MAP.dds
    ./.tools/tutorial-conversion/input/texture/grille1_MAP.png
    ./.tools/tutorial-conversion/input/texture/grille1_NM.dds
    ./.tools/tutorial-conversion/input/texture/grille1_NM.png
    ./.tools/tutorial-conversion/input/texture/grille1_SPEC.dds
    ./.tools/tutorial-conversion/input/texture/grille1_SPEC.png
    ./.tools/tutorial-conversion/input/texture/grille2.dds
    ./.tools/tutorial-conversion/input/texture/grille2.png
    ./.tools/tutorial-conversion/input/texture/grille2_MAP.dds
    ./.tools/tutorial-conversion/input/texture/grille2_MAP.png
    ./.tools/tutorial-conversion/input/texture/grille2_NM.dds
    ./.tools/tutorial-conversion/input/texture/grille2_NM.png
    ./.tools/tutorial-conversion/input/texture/grille2_red.dds
    ./.tools/tutorial-conversion/input/texture/grille2_spec.dds
    ./.tools/tutorial-conversion/input/texture/grille2_spec.png
    ./.tools/tutorial-conversion/input/texture/grille_MAP.dds
    ./.tools/tutorial-conversion/input/texture/grille_MAP.png
    ./.tools/tutorial-conversion/input/texture/grille_NM.dds
    ./.tools/tutorial-conversion/input/texture/grille_NM.png
    ./.tools/tutorial-conversion/input/texture/grille_Spec.dds
    ./.tools/tutorial-conversion/input/texture/grille_Spec.png
    ./.tools/tutorial-conversion/input/texture/groove.dds
    ./.tools/tutorial-conversion/input/texture/ground spons 2.dds
    ./.tools/tutorial-conversion/input/texture/gstand-detail2.dds
    ./.tools/tutorial-conversion/input/texture/gstand-detail2.png
    ./.tools/tutorial-conversion/input/texture/gstand-detail2_MAP.dds
    ./.tools/tutorial-conversion/input/texture/gstand-detail2_MAP.png
    ./.tools/tutorial-conversion/input/texture/gstand-detail3.dds
    ./.tools/tutorial-conversion/input/texture/gstand-detail3.png
    ./.tools/tutorial-conversion/input/texture/gstand-detail3_MAP.dds
    ./.tools/tutorial-conversion/input/texture/gstand-detail3_MAP.png
    ./.tools/tutorial-conversion/input/texture/gstand-detail3_NM.dds
    ./.tools/tutorial-conversion/input/texture/gstand-detail3_NM.png
    ./.tools/tutorial-conversion/input/texture/gstand_base_A.dds
    ./.tools/tutorial-conversion/input/texture/gstand_base_A.png
    ./.tools/tutorial-conversion/input/texture/gstand_base_MAP.dds
    ./.tools/tutorial-conversion/input/texture/gstand_base_MAP.png
    ./.tools/tutorial-conversion/input/texture/gstand_base_NM.dds
    ./.tools/tutorial-conversion/input/texture/gstand_base_NM.png
    ./.tools/tutorial-conversion/input/texture/gstand_base_WNM.png
    ./.tools/tutorial-conversion/input/texture/gude-2023-06-23.log
    ./.tools/tutorial-conversion/input/texture/itpine_E.dds
    ./.tools/tutorial-conversion/input/texture/ivy_hi.dds
    ./.tools/tutorial-conversion/input/texture/ivy_hi.png
    ./.tools/tutorial-conversion/input/texture/ivy_hi_AO.dds
    ./.tools/tutorial-conversion/input/texture/ivy_hi_AO.png
    ./.tools/tutorial-conversion/input/texture/ivy_hi_NM.dds
    ./.tools/tutorial-conversion/input/texture/ivy_hi_NM.png
    ./.tools/tutorial-conversion/input/texture/jersey.dds
    ./.tools/tutorial-conversion/input/texture/jersey_map.dds
    ./.tools/tutorial-conversion/input/texture/jersey_nm.dds
    ./.tools/tutorial-conversion/input/texture/lapdisplay.dds
    ./.tools/tutorial-conversion/input/texture/ledwall.dds
    ./.tools/tutorial-conversion/input/texture/line2.dds
    ./.tools/tutorial-conversion/input/texture/marbles.dds
    ./.tools/tutorial-conversion/input/texture/marshall-box.dds
    ./.tools/tutorial-conversion/input/texture/marshall-box.png
    ./.tools/tutorial-conversion/input/texture/marshall-box_MAP.dds
    ./.tools/tutorial-conversion/input/texture/marshall-box_MAP.png
    ./.tools/tutorial-conversion/input/texture/marshallA.dds
    ./.tools/tutorial-conversion/input/texture/marshallA.png
    ./.tools/tutorial-conversion/input/texture/marshallA_MAP.dds
    ./.tools/tutorial-conversion/input/texture/marshallA_MAP.png
    ./.tools/tutorial-conversion/input/texture/metal_dt_1.dds
    ./.tools/tutorial-conversion/input/texture/metal_plate_1.dds
    ./.tools/tutorial-conversion/input/texture/metal_plate_1_A.dds
    ./.tools/tutorial-conversion/input/texture/metal_plate_1_A.png
    ./.tools/tutorial-conversion/input/texture/metal_plate_1_NM.dds
    ./.tools/tutorial-conversion/input/texture/metal_plate_1_NM.png
    ./.tools/tutorial-conversion/input/texture/metal_plate_roof.dds
    ./.tools/tutorial-conversion/input/texture/metal_plate_tile_1.dds
    ./.tools/tutorial-conversion/input/texture/mid_NM.dds
    ./.tools/tutorial-conversion/input/texture/misc.dds
    ./.tools/tutorial-conversion/input/texture/misc.png
    ./.tools/tutorial-conversion/input/texture/misc_map.dds
    ./.tools/tutorial-conversion/input/texture/misc_map.png
    ./.tools/tutorial-conversion/input/texture/net-alpha.dds
    ./.tools/tutorial-conversion/input/texture/net-alpha.png
    ./.tools/tutorial-conversion/input/texture/panels.dds
    ./.tools/tutorial-conversion/input/texture/panels.png
    ./.tools/tutorial-conversion/input/texture/panelsAO.hdr
    ./.tools/tutorial-conversion/input/texture/panels_NM.dds
    ./.tools/tutorial-conversion/input/texture/panels_NM.png
    ./.tools/tutorial-conversion/input/texture/paratie1.dds
    ./.tools/tutorial-conversion/input/texture/paratie1.png
    ./.tools/tutorial-conversion/input/texture/paratie1_NM.dds
    ./.tools/tutorial-conversion/input/texture/paratie1_NM.png
    ./.tools/tutorial-conversion/input/texture/pine_leaf.dds
    ./.tools/tutorial-conversion/input/texture/pitlane-build1.dds
    ./.tools/tutorial-conversion/input/texture/pitlane-build1.png
    ./.tools/tutorial-conversion/input/texture/pitlane-build1_Emissive.dds
    ./.tools/tutorial-conversion/input/texture/pitlane-build1_Emissive.png
    ./.tools/tutorial-conversion/input/texture/pitlane-build1_MASK1.dds
    ./.tools/tutorial-conversion/input/texture/pitlane-build1_MASK1.png
    ./.tools/tutorial-conversion/input/texture/pitlane-build_MAP.dds
    ./.tools/tutorial-conversion/input/texture/pitlane-build_MAP.png
    ./.tools/tutorial-conversion/input/texture/pitlane-build_NM.dds
    ./.tools/tutorial-conversion/input/texture/pitlane-build_NM.png
    ./.tools/tutorial-conversion/input/texture/podium.dds
    ./.tools/tutorial-conversion/input/texture/podium.png
    ./.tools/tutorial-conversion/input/texture/pole1.dds
    ./.tools/tutorial-conversion/input/texture/pole1.png
    ./.tools/tutorial-conversion/input/texture/poly2.dds
    ./.tools/tutorial-conversion/input/texture/red-pitlane.dds
    ./.tools/tutorial-conversion/input/texture/red-pitlane.png
    ./.tools/tutorial-conversion/input/texture/red-pitlane_MAP.dds
    ./.tools/tutorial-conversion/input/texture/red-pitlane_MAP.png
    ./.tools/tutorial-conversion/input/texture/red-pitlane_NM.dds
    ./.tools/tutorial-conversion/input/texture/red-pitlane_NM.png
    ./.tools/tutorial-conversion/input/texture/red.dds
    ./.tools/tutorial-conversion/input/texture/rideGreen.dds
    ./.tools/tutorial-conversion/input/texture/rideGreen.png
    ./.tools/tutorial-conversion/input/texture/road-concrete-ext.dds
    ./.tools/tutorial-conversion/input/texture/road-concrete-ext.png
    ./.tools/tutorial-conversion/input/texture/road-concrete-ext_NM.dds
    ./.tools/tutorial-conversion/input/texture/road-concrete-ext_NM.png
    ./.tools/tutorial-conversion/input/texture/road-concrete-ext_mask.dds
    ./.tools/tutorial-conversion/input/texture/road-concrete-ext_mask.png
    ./.tools/tutorial-conversion/input/texture/roof-tile_D.dds
    ./.tools/tutorial-conversion/input/texture/roof-tile_D.png
    ./.tools/tutorial-conversion/input/texture/roof-tile_MAP.dds
    ./.tools/tutorial-conversion/input/texture/roof-tile_MAP.png
    ./.tools/tutorial-conversion/input/texture/roof-tile_NM.dds
    ./.tools/tutorial-conversion/input/texture/roof-tile_NM.png
    ./.tools/tutorial-conversion/input/texture/rumble-strip-b.dds
    ./.tools/tutorial-conversion/input/texture/rumble-strip-b.png
    ./.tools/tutorial-conversion/input/texture/rumble-strip-b_MAP.dds
    ./.tools/tutorial-conversion/input/texture/rumble-strip-b_MAP.png
    ./.tools/tutorial-conversion/input/texture/rumble-strip-b_NM.dds
    ./.tools/tutorial-conversion/input/texture/rumble-strip-b_NM.png
    ./.tools/tutorial-conversion/input/texture/rumble-strip-b_height.dds
    ./.tools/tutorial-conversion/input/texture/rumble-strip-b_height.png
    ./.tools/tutorial-conversion/input/texture/rumble-strip-b_wetmask.dds
    ./.tools/tutorial-conversion/input/texture/rumble-strip-b_wetmask.png
    ./.tools/tutorial-conversion/input/texture/rumble-strip-c.dds
    ./.tools/tutorial-conversion/input/texture/rumble-stripMAP.dds
    ./.tools/tutorial-conversion/input/texture/rumble-stripNM-A.dds
    ./.tools/tutorial-conversion/input/texture/sand_base - Copy.dds
    ./.tools/tutorial-conversion/input/texture/sand_base.dds
    ./.tools/tutorial-conversion/input/texture/sand_base_MAP.dds
    ./.tools/tutorial-conversion/input/texture/sand_base_NM.dds
    ./.tools/tutorial-conversion/input/texture/sand_brd2 - Copy.dds
    ./.tools/tutorial-conversion/input/texture/sand_brd2.dds
    ./.tools/tutorial-conversion/input/texture/sat2.dds
    ./.tools/tutorial-conversion/input/texture/sat2.png
    ./.tools/tutorial-conversion/input/texture/sat2B.dds
    ./.tools/tutorial-conversion/input/texture/semaphore.dds
    ./.tools/tutorial-conversion/input/texture/series logo.dds
    ./.tools/tutorial-conversion/input/texture/slow-curb.dds
    ./.tools/tutorial-conversion/input/texture/slow-curb.png
    ./.tools/tutorial-conversion/input/texture/slow-curb_MAP.dds
    ./.tools/tutorial-conversion/input/texture/slow-curb_MAP.png
    ./.tools/tutorial-conversion/input/texture/slow-curb_NM.dds
    ./.tools/tutorial-conversion/input/texture/slow-curb_NM.png
    ./.tools/tutorial-conversion/input/texture/soil_mid_ext3.dds
    ./.tools/tutorial-conversion/input/texture/soil_mid_ext4.dds
    ./.tools/tutorial-conversion/input/texture/soil_mid_ext4_NM.dds
    ./.tools/tutorial-conversion/input/texture/sp_bumps.dds
    ./.tools/tutorial-conversion/input/texture/sp_bumps.png
    ./.tools/tutorial-conversion/input/texture/sponsors 2.dds
    ./.tools/tutorial-conversion/input/texture/sponsors 2.psd
    ./.tools/tutorial-conversion/input/texture/sponsors-ground1.dds
    ./.tools/tutorial-conversion/input/texture/sponsors-ground1.png
    ./.tools/tutorial-conversion/input/texture/sponsors.dds
    ./.tools/tutorial-conversion/input/texture/sponsors.png
    ./.tools/tutorial-conversion/input/texture/sponsors_MAP.dds
    ./.tools/tutorial-conversion/input/texture/sponsors_NM.dds
    ./.tools/tutorial-conversion/input/texture/sponsors_NM.png
    ./.tools/tutorial-conversion/input/texture/struc-green-ext.dds
    ./.tools/tutorial-conversion/input/texture/struc-green-ext.png
    ./.tools/tutorial-conversion/input/texture/struc-green-ext_NM.dds
    ./.tools/tutorial-conversion/input/texture/struc-green-ext_NM.png
    ./.tools/tutorial-conversion/input/texture/structures-alpha.dds
    ./.tools/tutorial-conversion/input/texture/structures-alpha.png
    ./.tools/tutorial-conversion/input/texture/structures-alpha_MAP.dds
    ./.tools/tutorial-conversion/input/texture/structures-alpha_MAP.png
    ./.tools/tutorial-conversion/input/texture/structures-base.dds
    ./.tools/tutorial-conversion/input/texture/structures-base.png
    ./.tools/tutorial-conversion/input/texture/structures-base_MAP.dds
    ./.tools/tutorial-conversion/input/texture/stucco_1.dds
    ./.tools/tutorial-conversion/input/texture/stucco_1_NM.dds
    ./.tools/tutorial-conversion/input/texture/tarmac-detail5.dds
    ./.tools/tutorial-conversion/input/texture/tarmac-detail5_NM2.dds
    ./.tools/tutorial-conversion/input/texture/tarmac_green.dds
    ./.tools/tutorial-conversion/input/texture/tarmac_green.png
    ./.tools/tutorial-conversion/input/texture/tent-fabric1.dds
    ./.tools/tutorial-conversion/input/texture/tiles_detail1.dds
    ./.tools/tutorial-conversion/input/texture/tiles_detail1.png
    ./.tools/tutorial-conversion/input/texture/tiles_detail2.dds
    ./.tools/tutorial-conversion/input/texture/tiles_detail2.png
    ./.tools/tutorial-conversion/input/texture/tiles_detail2_NM.dds
    ./.tools/tutorial-conversion/input/texture/tiles_detail2_NM.png
    ./.tools/tutorial-conversion/input/texture/tiles_detail3.dds
    ./.tools/tutorial-conversion/input/texture/tiles_detail3.png
    ./.tools/tutorial-conversion/input/texture/tiles_detail3_NM.dds
    ./.tools/tutorial-conversion/input/texture/tiles_detail3_NM.png
    ./.tools/tutorial-conversion/input/texture/tiles_detail4.dds
    ./.tools/tutorial-conversion/input/texture/tiles_detail4.png
    ./.tools/tutorial-conversion/input/texture/tiles_detail4_NM.dds
    ./.tools/tutorial-conversion/input/texture/tiles_detail4_NM.png
    ./.tools/tutorial-conversion/input/texture/time-tower.dds
    ./.tools/tutorial-conversion/input/texture/time-tower.png
    ./.tools/tutorial-conversion/input/texture/time-tower_emissive.dds
    ./.tools/tutorial-conversion/input/texture/time-tower_emissive.png
    ./.tools/tutorial-conversion/input/texture/time-tower_map.dds
    ./.tools/tutorial-conversion/input/texture/time-tower_map.png
    ./.tools/tutorial-conversion/input/texture/tower spons.dds
    ./.tools/tutorial-conversion/input/texture/tower spons.psd
    ./.tools/tutorial-conversion/input/texture/tower.psd
    ./.tools/tutorial-conversion/input/texture/towerdisplay.dds
    ./.tools/tutorial-conversion/input/texture/trap_detail.dds
    ./.tools/tutorial-conversion/input/texture/trap_detail_NM3.dds
    ./.tools/tutorial-conversion/input/texture/tree_shadow.dds
    ./.tools/tutorial-conversion/input/texture/trees2G.dds
    ./.tools/tutorial-conversion/input/texture/tyres_B.dds
    ./.tools/tutorial-conversion/input/texture/tyres_B_NMYB.dds
    ./.tools/tutorial-conversion/input/texture/tyres_MAP.dds
    ./.tools/tutorial-conversion/input/texture/tyres_add1.dds
    ./.tools/tutorial-conversion/input/texture/tyres_add2.dds
    ./.tools/tutorial-conversion/input/texture/wall_detail.dds
    ./.tools/tutorial-conversion/input/texture/wall_detail.png
    ./.tools/tutorial-conversion/input/texture/wall_detail_NM.dds
    ./.tools/tutorial-conversion/input/texture/wall_detail_NM.png
    ./.tools/tutorial-conversion/input/texture/walls1.dds
    ./.tools/tutorial-conversion/input/texture/walls1.png
    ./.tools/tutorial-conversion/input/texture/walls1_MAP.dds
    ./.tools/tutorial-conversion/input/texture/walls1_NM.dds
    ./.tools/tutorial-conversion/input/texture/walls1_NM.png
    ./.tools/tutorial-conversion/input/texture/walls1_wetmask.dds
    ./.tools/tutorial-conversion/input/texture/walls1_wetmask.png
    ./.tools/tutorial-conversion/input/texture/walls1b.dds
    ./.tools/tutorial-conversion/input/texture/white.dds
    ./.tools/tutorial-conversion/input/texture/whiteline.dds
    ./.tools/tutorial-conversion/input/texture/whiteline3.dds
    ./.tools/tutorial-conversion/input/texture/whiteline4.dds
    ./.tools/tutorial-conversion/input/texture/whiteline5.dds
    ./.tools/tutorial-conversion/jes-kn5-converter/.git/HEAD
    ./.tools/tutorial-conversion/jes-kn5-converter/.git/config
    ./.tools/tutorial-conversion/jes-kn5-converter/.git/description
    ./.tools/tutorial-conversion/jes-kn5-converter/.git/hooks/applypatch-msg.sample
    ./.tools/tutorial-conversion/jes-kn5-converter/.git/hooks/commit-msg.sample
    ./.tools/tutorial-conversion/jes-kn5-converter/.git/hooks/fsmonitor-watchman.sample
    ./.tools/tutorial-conversion/jes-kn5-converter/.git/hooks/post-update.sample
    ./.tools/tutorial-conversion/jes-kn5-converter/.git/hooks/pre-applypatch.sample
    ./.tools/tutorial-conversion/jes-kn5-converter/.git/hooks/pre-commit.sample
    ./.tools/tutorial-conversion/jes-kn5-converter/.git/hooks/pre-merge-commit.sample
    ./.tools/tutorial-conversion/jes-kn5-converter/.git/hooks/pre-push.sample
    ./.tools/tutorial-conversion/jes-kn5-converter/.git/hooks/pre-rebase.sample
    ./.tools/tutorial-conversion/jes-kn5-converter/.git/hooks/pre-receive.sample
    ./.tools/tutorial-conversion/jes-kn5-converter/.git/hooks/prepare-commit-msg.sample
    ./.tools/tutorial-conversion/jes-kn5-converter/.git/hooks/push-to-checkout.sample
    ./.tools/tutorial-conversion/jes-kn5-converter/.git/hooks/sendemail-validate.sample
    ./.tools/tutorial-conversion/jes-kn5-converter/.git/hooks/update.sample
    ./.tools/tutorial-conversion/jes-kn5-converter/.git/index
    ./.tools/tutorial-conversion/jes-kn5-converter/.git/info/exclude
    ./.tools/tutorial-conversion/jes-kn5-converter/.git/logs/HEAD
    ./.tools/tutorial-conversion/jes-kn5-converter/.git/logs/refs/heads/master
    ./.tools/tutorial-conversion/jes-kn5-converter/.git/logs/refs/remotes/origin/HEAD
    ./.tools/tutorial-conversion/jes-kn5-converter/.git/objects/pack/pack-db2f73f7ba0dfeada2a76900f88b407abd1724b0.idx
    ./.tools/tutorial-conversion/jes-kn5-converter/.git/objects/pack/pack-db2f73f7ba0dfeada2a76900f88b407abd1724b0.pack
    ./.tools/tutorial-conversion/jes-kn5-converter/.git/objects/pack/pack-db2f73f7ba0dfeada2a76900f88b407abd1724b0.rev
    ./.tools/tutorial-conversion/jes-kn5-converter/.git/packed-refs
    ./.tools/tutorial-conversion/jes-kn5-converter/.git/refs/heads/master
    ./.tools/tutorial-conversion/jes-kn5-converter/.git/refs/remotes/origin/HEAD
    ./.tools/tutorial-conversion/jes-kn5-converter/.git/shallow
    ./.tools/tutorial-conversion/jes-kn5-converter/Makefile
    ./.tools/tutorial-conversion/jes-kn5-converter/README
    ./.tools/tutorial-conversion/jes-kn5-converter/kn5conv.cs
    ./.tools/tutorial-conversion/kn5conv/bin/Release/net10.0/kn5conv
    ./.tools/tutorial-conversion/kn5conv/bin/Release/net10.0/kn5conv.deps.json
    ./.tools/tutorial-conversion/kn5conv/bin/Release/net10.0/kn5conv.dll
    ./.tools/tutorial-conversion/kn5conv/bin/Release/net10.0/kn5conv.pdb
    ./.tools/tutorial-conversion/kn5conv/bin/Release/net10.0/kn5conv.runtimeconfig.json
    ./.tools/tutorial-conversion/kn5conv/kn5conv.cs
    ./.tools/tutorial-conversion/kn5conv/kn5conv.csproj
    ./.tools/tutorial-conversion/kn5conv/obj/Release/net10.0/.NETCoreApp,Version=v10.0.AssemblyAttributes.cs
    ./.tools/tutorial-conversion/kn5conv/obj/Release/net10.0/apphost
    ./.tools/tutorial-conversion/kn5conv/obj/Release/net10.0/kn5conv.AssemblyInfo.cs
    ./.tools/tutorial-conversion/kn5conv/obj/Release/net10.0/kn5conv.AssemblyInfoInputs.cache
    ./.tools/tutorial-conversion/kn5conv/obj/Release/net10.0/kn5conv.GeneratedMSBuildEditorConfig.editorconfig
    ./.tools/tutorial-conversion/kn5conv/obj/Release/net10.0/kn5conv.assets.cache
    ./.tools/tutorial-conversion/kn5conv/obj/Release/net10.0/kn5conv.csproj.CoreCompileInputs.cache
    ./.tools/tutorial-conversion/kn5conv/obj/Release/net10.0/kn5conv.csproj.FileListAbsolute.txt
    ./.tools/tutorial-conversion/kn5conv/obj/Release/net10.0/kn5conv.dll
    ./.tools/tutorial-conversion/kn5conv/obj/Release/net10.0/kn5conv.genruntimeconfig.cache
    ./.tools/tutorial-conversion/kn5conv/obj/Release/net10.0/kn5conv.pdb
    ./.tools/tutorial-conversion/kn5conv/obj/Release/net10.0/ref/kn5conv.dll
    ./.tools/tutorial-conversion/kn5conv/obj/Release/net10.0/refint/kn5conv.dll
    ./.tools/tutorial-conversion/kn5conv/obj/kn5conv.csproj.nuget.dgspec.json
    ./.tools/tutorial-conversion/kn5conv/obj/kn5conv.csproj.nuget.g.props
    ./.tools/tutorial-conversion/kn5conv/obj/kn5conv.csproj.nuget.g.targets
    ./.tools/tutorial-conversion/kn5conv/obj/project.assets.json
    ./.tools/tutorial-conversion/kn5conv/obj/project.nuget.cache
    ./.tools/tutorial-conversion/logs/100.log
    ./.tools/tutorial-conversion/logs/4.log
    ./.tools/tutorial-conversion/logs/8.log
    ./.tools/tutorial-conversion/logs/9.log
    ./.tools/tutorial-conversion/logs/ac2026-archive-list.txt
    ./.tools/tutorial-conversion/logs/ac2026-checksums.before.txt
    ./.tools/tutorial-conversion/logs/android-export-tutorial.log
    ./.tools/tutorial-conversion/logs/android-install-tutorial.log
    ./.tools/tutorial-conversion/logs/barcelona_2023_5.log
    ./.tools/tutorial-conversion/logs/barcelona_remastered.log
    ./.tools/tutorial-conversion/logs/barcelona_remastered_physics.log
    ./.tools/tutorial-conversion/logs/barcelona_remastered_physics_moto.log
    ./.tools/tutorial-conversion/logs/blender-export-batch.log
    ./.tools/tutorial-conversion/logs/blender-export-final.log
    ./.tools/tutorial-conversion/logs/blender-export-textured.log
    ./.tools/tutorial-conversion/logs/blender-import-final.log
    ./.tools/tutorial-conversion/logs/blender-import.log
    ./.tools/tutorial-conversion/logs/blender-pack-textures.log
    ./.tools/tutorial-conversion/logs/blender-rebuild-embedded-textures-ok.log
    ./.tools/tutorial-conversion/logs/blender-rebuild-final.log
    ./.tools/tutorial-conversion/logs/blender-rebuild-mats.log
    ./.tools/tutorial-conversion/logs/blender-rebuild-preserve-textures.log
    ./.tools/tutorial-conversion/logs/blender-rebuild-textures-embedded.log
    ./.tools/tutorial-conversion/logs/blender-rebuild-textures-final.log
    ./.tools/tutorial-conversion/logs/blender-rebuild-textures-final2.log
    ./.tools/tutorial-conversion/logs/blender-rebuild-textures-final3.log
    ./.tools/tutorial-conversion/logs/blender-rebuild-textures-final4.log
    ./.tools/tutorial-conversion/logs/blender-rebuild-textures-final5.log
    ./.tools/tutorial-conversion/logs/blender-rebuild-textures-final6.log
    ./.tools/tutorial-conversion/logs/blender-rebuild-textures-full.log
    ./.tools/tutorial-conversion/logs/blender-rebuild-textures-verified.log
    ./.tools/tutorial-conversion/logs/blender-rebuild-tutorial.log
    ./.tools/tutorial-conversion/logs/blender-reload-textures.log
    ./.tools/tutorial-conversion/logs/blender-texture-export-pack.log
    ./.tools/tutorial-conversion/logs/blender-texture-export-pack2.log
    ./.tools/tutorial-conversion/logs/dynamics-probe-final.log
    ./.tools/tutorial-conversion/logs/dynamics_probe-delivery.log
    ./.tools/tutorial-conversion/logs/dynamics_probe-final.log
    ./.tools/tutorial-conversion/logs/dynamics_probe-review-final.log
    ./.tools/tutorial-conversion/logs/emulator-before-axis-fix.png
    ./.tools/tutorial-conversion/logs/emulator-before-axis-preview.png
    ./.tools/tutorial-conversion/logs/emulator-first-run.png
    ./.tools/tutorial-conversion/logs/emulator-preview.png
    ./.tools/tutorial-conversion/logs/emulator-second-run.png
    ./.tools/tutorial-conversion/logs/glb-embedded-textures.json
    ./.tools/tutorial-conversion/logs/godot-after-touchfix.log
    ./.tools/tutorial-conversion/logs/godot-editor-import.log
    ./.tools/tutorial-conversion/logs/godot-editor-reparse.log
    ./.tools/tutorial-conversion/logs/godot-final-headless-check.log
    ./.tools/tutorial-conversion/logs/godot-final-test.log
    ./.tools/tutorial-conversion/logs/godot-fixed-multi-import.log
    ./.tools/tutorial-conversion/logs/godot-import-existing.log
    ./.tools/tutorial-conversion/logs/godot-import-glbs.log
    ./.tools/tutorial-conversion/logs/godot-import-glbs2.log
    ./.tools/tutorial-conversion/logs/godot-mat-rebind-check.log
    ./.tools/tutorial-conversion/logs/godot-run-axis-rebuild.log
    ./.tools/tutorial-conversion/logs/godot-run-check.log
    ./.tools/tutorial-conversion/logs/godot-tutorial-track-import.log
    ./.tools/tutorial-conversion/logs/jes-kn5-converter-Makefile.txt
    ./.tools/tutorial-conversion/logs/jes-kn5-converter-readme.txt
    ./.tools/tutorial-conversion/logs/kn5conv-dotnet-build.log
    ./.tools/tutorial-conversion/logs/kn5conv-moto-layer.log
    ./.tools/tutorial-conversion/logs/lap-probe-final.log
    ./.tools/tutorial-conversion/logs/lap_probe-delivery.log
    ./.tools/tutorial-conversion/logs/lap_probe-final.log
    ./.tools/tutorial-conversion/logs/lap_probe-review-final.log
    ./.tools/tutorial-conversion/logs/runtime-probe-after-fix.log
    ./.tools/tutorial-conversion/logs/runtime-probe-after-grip.log
    ./.tools/tutorial-conversion/logs/runtime-probe-final.log
    ./.tools/tutorial-conversion/logs/runtime-probe-track-test.log
    ./.tools/tutorial-conversion/logs/runtime-probe-track-test2.log
    ./.tools/tutorial-conversion/logs/runtime_probe-delivery.log
    ./.tools/tutorial-conversion/logs/runtime_probe-final.log
    ./.tools/tutorial-conversion/logs/runtime_probe-review-final.log
    ./.tools/tutorial-conversion/logs/track_probe-delivery.log
    ./.tools/tutorial-conversion/obj/100.mtl
    ./.tools/tutorial-conversion/obj/100.obj
    ./.tools/tutorial-conversion/obj/4.mtl
    ./.tools/tutorial-conversion/obj/4.obj
    ./.tools/tutorial-conversion/obj/8.mtl
    ./.tools/tutorial-conversion/obj/8.obj
    ./.tools/tutorial-conversion/obj/9.mtl
    ./.tools/tutorial-conversion/obj/9.obj
    ./.tools/tutorial-conversion/obj/barcelona_2023_5.mtl
    ./.tools/tutorial-conversion/obj/barcelona_2023_5.obj
    ./.tools/tutorial-conversion/obj/barcelona_remastered.mtl
    ./.tools/tutorial-conversion/obj/barcelona_remastered.obj
    ./.tools/tutorial-conversion/obj/barcelona_remastered_moto.mtl
    ./.tools/tutorial-conversion/obj/barcelona_remastered_moto.obj
    ./.tools/tutorial-conversion/obj/barcelona_remastered_physics.mtl
    ./.tools/tutorial-conversion/obj/barcelona_remastered_physics.obj
    ./.tools/tutorial-conversion/obj/barcelona_remastered_physics_moto.mtl
    ./.tools/tutorial-conversion/obj/barcelona_remastered_physics_moto.obj
    ./.tools/tutorial-conversion/obj/texture/3dt3B.dds
    ./.tools/tutorial-conversion/obj/texture/3dt3B.png
    ./.tools/tutorial-conversion/obj/texture/Barcellona_Box_A.dds
    ./.tools/tutorial-conversion/obj/texture/Barcellona_Box_A.png
    ./.tools/tutorial-conversion/obj/texture/BricksWall.dds
    ./.tools/tutorial-conversion/obj/texture/BricksWall.png
    ./.tools/tutorial-conversion/obj/texture/BricksWall_MAP_rough4.png
    ./.tools/tutorial-conversion/obj/texture/BricksWall_NM.dds
    ./.tools/tutorial-conversion/obj/texture/BricksWall_NM.png
    ./.tools/tutorial-conversion/obj/texture/Concrete_detail.dds
    ./.tools/tutorial-conversion/obj/texture/Concrete_detail.png
    ./.tools/tutorial-conversion/obj/texture/Concrete_detail_3.dds
    ./.tools/tutorial-conversion/obj/texture/Concrete_detail_3.png
    ./.tools/tutorial-conversion/obj/texture/Concrete_detail_4.dds
    ./.tools/tutorial-conversion/obj/texture/Concrete_detail_4.png
    ./.tools/tutorial-conversion/obj/texture/Concrete_wall.dds
    ./.tools/tutorial-conversion/obj/texture/Concrete_wall.png
    ./.tools/tutorial-conversion/obj/texture/DRIVER_Face.dds
    ./.tools/tutorial-conversion/obj/texture/DRIVER_Face.png
    ./.tools/tutorial-conversion/obj/texture/DRIVER_Suit.dds
    ./.tools/tutorial-conversion/obj/texture/DRIVER_Suit.png
    ./.tools/tutorial-conversion/obj/texture/Garage_Colour.dds
    ./.tools/tutorial-conversion/obj/texture/Garage_Colour.png
    ./.tools/tutorial-conversion/obj/texture/GrandStand_base.dds
    ./.tools/tutorial-conversion/obj/texture/GrandStand_base.png
    ./.tools/tutorial-conversion/obj/texture/GrandStand_base_MAP_rough1.png
    ./.tools/tutorial-conversion/obj/texture/GrandStand_base_MAP_rough2.png
    ./.tools/tutorial-conversion/obj/texture/GrandStand_base_MAP_rough44.png
    ./.tools/tutorial-conversion/obj/texture/GrandStand_base_NMW5.dds
    ./.tools/tutorial-conversion/obj/texture/GrandStand_base_NMW5.png
    ./.tools/tutorial-conversion/obj/texture/Grass0151_A.dds
    ./.tools/tutorial-conversion/obj/texture/Grass0151_A.png
    ./.tools/tutorial-conversion/obj/texture/Lights_Emissive_DIF.dds
    ./.tools/tutorial-conversion/obj/texture/Lights_Emissive_DIF.png
    ./.tools/tutorial-conversion/obj/texture/NULL.dds
    ./.tools/tutorial-conversion/obj/texture/NULL.png
    ./.tools/tutorial-conversion/obj/texture/Props_PITLANE.dds
    ./.tools/tutorial-conversion/obj/texture/Props_PITLANE.png
    ./.tools/tutorial-conversion/obj/texture/Props_PITLANE_NM.dds
    ./.tools/tutorial-conversion/obj/texture/Props_PITLANE_NM.png
    ./.tools/tutorial-conversion/obj/texture/Rust-detail1.dds
    ./.tools/tutorial-conversion/obj/texture/Rust-detail1.png
    ./.tools/tutorial-conversion/obj/texture/Wood_plank.dds
    ./.tools/tutorial-conversion/obj/texture/Wood_plank.png
    ./.tools/tutorial-conversion/obj/texture/Wood_plank_MAP_rough2.png
    ./.tools/tutorial-conversion/obj/texture/Wood_plank_NM.dds
    ./.tools/tutorial-conversion/obj/texture/Wood_plank_NM.png
    ./.tools/tutorial-conversion/obj/texture/ac_crew.dds
    ./.tools/tutorial-conversion/obj/texture/ac_crew.png
    ./.tools/tutorial-conversion/obj/texture/ao-ext.dds
    ./.tools/tutorial-conversion/obj/texture/ao-ext.png
    ./.tools/tutorial-conversion/obj/texture/asd.dds
    ./.tools/tutorial-conversion/obj/texture/asd.png
    ./.tools/tutorial-conversion/obj/texture/asph-red.dds
    ./.tools/tutorial-conversion/obj/texture/asph-red.png
    ./.tools/tutorial-conversion/obj/texture/asph-red_MAP_rough1.png
    ./.tools/tutorial-conversion/obj/texture/asph-red_MAP_rough3.png
    ./.tools/tutorial-conversion/obj/texture/asph-white.dds
    ./.tools/tutorial-conversion/obj/texture/asph-white.png
    ./.tools/tutorial-conversion/obj/texture/asph8_2048.dds
    ./.tools/tutorial-conversion/obj/texture/asph8_2048.png
    ./.tools/tutorial-conversion/obj/texture/asph_updt.dds
    ./.tools/tutorial-conversion/obj/texture/asph_updt.png
    ./.tools/tutorial-conversion/obj/texture/background_B.dds
    ./.tools/tutorial-conversion/obj/texture/background_B.png
    ./.tools/tutorial-conversion/obj/texture/barcelona t10.dds
    ./.tools/tutorial-conversion/obj/texture/barcelona t10.png
    ./.tools/tutorial-conversion/obj/texture/bark.dds
    ./.tools/tutorial-conversion/obj/texture/bark.png
    ./.tools/tutorial-conversion/obj/texture/barrier.dds
    ./.tools/tutorial-conversion/obj/texture/barrier.png
    ./.tools/tutorial-conversion/obj/texture/black.dds
    ./.tools/tutorial-conversion/obj/texture/black.png
    ./.tools/tutorial-conversion/obj/texture/box-fence.dds
    ./.tools/tutorial-conversion/obj/texture/box-fence.png
    ./.tools/tutorial-conversion/obj/texture/box-numbers.dds
    ./.tools/tutorial-conversion/obj/texture/box-numbers.png
    ./.tools/tutorial-conversion/obj/texture/box-wall.dds
    ./.tools/tutorial-conversion/obj/texture/box-wall.png
    ./.tools/tutorial-conversion/obj/texture/box-wall_MAP_rough18.png
    ./.tools/tutorial-conversion/obj/texture/box-wall_NM.dds
    ./.tools/tutorial-conversion/obj/texture/box-wall_NM.png
    ./.tools/tutorial-conversion/obj/texture/box1.dds
    ./.tools/tutorial-conversion/obj/texture/box1.png
    ./.tools/tutorial-conversion/obj/texture/box1_MAP_rough1.png
    ./.tools/tutorial-conversion/obj/texture/box1_MAP_rough2.png
    ./.tools/tutorial-conversion/obj/texture/box1_MAP_rough20.png
    ./.tools/tutorial-conversion/obj/texture/box1_MAP_rough7.png
    ./.tools/tutorial-conversion/obj/texture/box1_NM.dds
    ./.tools/tutorial-conversion/obj/texture/box1_NM.png
    ./.tools/tutorial-conversion/obj/texture/branch5.dds
    ./.tools/tutorial-conversion/obj/texture/branch5.png
    ./.tools/tutorial-conversion/obj/texture/bridge2.dds
    ./.tools/tutorial-conversion/obj/texture/bridge2.png
    ./.tools/tutorial-conversion/obj/texture/bridge2_MAP_rough5.png
    ./.tools/tutorial-conversion/obj/texture/bridge2_NM.dds
    ./.tools/tutorial-conversion/obj/texture/bridge2_NM.png
    ./.tools/tutorial-conversion/obj/texture/bridge_1B_MAP_rough1.png
    ./.tools/tutorial-conversion/obj/texture/bridge_1B_MAP_rough4.png
    ./.tools/tutorial-conversion/obj/texture/bridge_1_d.dds
    ./.tools/tutorial-conversion/obj/texture/bridge_1_d.png
    ./.tools/tutorial-conversion/obj/texture/bridge_normal.dds
    ./.tools/tutorial-conversion/obj/texture/bridge_normal.png
    ./.tools/tutorial-conversion/obj/texture/carpet-base_MAP_rough38.png
    ./.tools/tutorial-conversion/obj/texture/carpet.dds
    ./.tools/tutorial-conversion/obj/texture/carpet.png
    ./.tools/tutorial-conversion/obj/texture/carpet_NM.dds
    ./.tools/tutorial-conversion/obj/texture/carpet_NM.png
    ./.tools/tutorial-conversion/obj/texture/catalunya spons1.dds
    ./.tools/tutorial-conversion/obj/texture/catalunya spons1.png
    ./.tools/tutorial-conversion/obj/texture/clockdisplay.dds
    ./.tools/tutorial-conversion/obj/texture/clockdisplay.png
    ./.tools/tutorial-conversion/obj/texture/commissario_NEW.dds
    ./.tools/tutorial-conversion/obj/texture/commissario_NEW.png
    ./.tools/tutorial-conversion/obj/texture/concrete_box.dds
    ./.tools/tutorial-conversion/obj/texture/concrete_box.png
    ./.tools/tutorial-conversion/obj/texture/concrete_box_MAP_rough1.png
    ./.tools/tutorial-conversion/obj/texture/concrete_box_NM.dds
    ./.tools/tutorial-conversion/obj/texture/concrete_box_NM.png
    ./.tools/tutorial-conversion/obj/texture/concrete_white_old_albedo2.dds
    ./.tools/tutorial-conversion/obj/texture/concrete_white_old_albedo2.png
    ./.tools/tutorial-conversion/obj/texture/curb1_A.dds
    ./.tools/tutorial-conversion/obj/texture/curb1_A.png
    ./.tools/tutorial-conversion/obj/texture/curb1_NM.dds
    ./.tools/tutorial-conversion/obj/texture/curb1_NM.png
    ./.tools/tutorial-conversion/obj/texture/curb2.dds
    ./.tools/tutorial-conversion/obj/texture/curb2.png
    ./.tools/tutorial-conversion/obj/texture/curb2_NM.dds
    ./.tools/tutorial-conversion/obj/texture/curb2_NM.png
    ./.tools/tutorial-conversion/obj/texture/curb_typeB.dds
    ./.tools/tutorial-conversion/obj/texture/curb_typeB.png
    ./.tools/tutorial-conversion/obj/texture/curb_typeB_NM.dds
    ./.tools/tutorial-conversion/obj/texture/curb_typeB_NM.png
    ./.tools/tutorial-conversion/obj/texture/digitalflag.dds
    ./.tools/tutorial-conversion/obj/texture/digitalflag.png
    ./.tools/tutorial-conversion/obj/texture/digitalflag_main_alb.dds
    ./.tools/tutorial-conversion/obj/texture/digitalflag_main_alb.png
    ./.tools/tutorial-conversion/obj/texture/direction-villa.dds
    ./.tools/tutorial-conversion/obj/texture/direction-villa.png
    ./.tools/tutorial-conversion/obj/texture/distanz.dds
    ./.tools/tutorial-conversion/obj/texture/distanz.png
    ./.tools/tutorial-conversion/obj/texture/distanz_MAP_rough1.png
    ./.tools/tutorial-conversion/obj/texture/distanz_NM.dds
    ./.tools/tutorial-conversion/obj/texture/distanz_NM.png
    ./.tools/tutorial-conversion/obj/texture/drs.dds
    ./.tools/tutorial-conversion/obj/texture/drs.png
    ./.tools/tutorial-conversion/obj/texture/fences1.dds
    ./.tools/tutorial-conversion/obj/texture/fences1.png
    ./.tools/tutorial-conversion/obj/texture/fences2.dds
    ./.tools/tutorial-conversion/obj/texture/fences2.png
    ./.tools/tutorial-conversion/obj/texture/flat_NM.dds
    ./.tools/tutorial-conversion/obj/texture/flat_NM.png
    ./.tools/tutorial-conversion/obj/texture/glass-box.dds
    ./.tools/tutorial-conversion/obj/texture/glass-box.png
    ./.tools/tutorial-conversion/obj/texture/glass-name1.dds
    ./.tools/tutorial-conversion/obj/texture/glass-name1.png
    ./.tools/tutorial-conversion/obj/texture/grail.dds
    ./.tools/tutorial-conversion/obj/texture/grail.png
    ./.tools/tutorial-conversion/obj/texture/grail_MAP_rough60.png
    ./.tools/tutorial-conversion/obj/texture/grail_NM.dds
    ./.tools/tutorial-conversion/obj/texture/grail_NM.png
    ./.tools/tutorial-conversion/obj/texture/grass-brd-ext.dds
    ./.tools/tutorial-conversion/obj/texture/grass-brd-ext.png
    ./.tools/tutorial-conversion/obj/texture/grass-brd3-F.dds
    ./.tools/tutorial-conversion/obj/texture/grass-brd3-F.png
    ./.tools/tutorial-conversion/obj/texture/grass2_MAP_rough2.png
    ./.tools/tutorial-conversion/obj/texture/grass_base2.dds
    ./.tools/tutorial-conversion/obj/texture/grass_base2.png
    ./.tools/tutorial-conversion/obj/texture/gravel.dds
    ./.tools/tutorial-conversion/obj/texture/gravel.png
    ./.tools/tutorial-conversion/obj/texture/grille.dds
    ./.tools/tutorial-conversion/obj/texture/grille.png
    ./.tools/tutorial-conversion/obj/texture/grille2.dds
    ./.tools/tutorial-conversion/obj/texture/grille2.png
    ./.tools/tutorial-conversion/obj/texture/grille2_MAP_rough8.png
    ./.tools/tutorial-conversion/obj/texture/grille2_NM.dds
    ./.tools/tutorial-conversion/obj/texture/grille2_NM.png
    ./.tools/tutorial-conversion/obj/texture/grille2_red.dds
    ./.tools/tutorial-conversion/obj/texture/grille2_red.png
    ./.tools/tutorial-conversion/obj/texture/grille_MAP_rough3.png
    ./.tools/tutorial-conversion/obj/texture/grille_NM.dds
    ./.tools/tutorial-conversion/obj/texture/grille_NM.png
    ./.tools/tutorial-conversion/obj/texture/groove.dds
    ./.tools/tutorial-conversion/obj/texture/groove.png
    ./.tools/tutorial-conversion/obj/texture/ground spons 2.dds
    ./.tools/tutorial-conversion/obj/texture/ground spons 2.png
    ./.tools/tutorial-conversion/obj/texture/gstand-detail2.dds
    ./.tools/tutorial-conversion/obj/texture/gstand-detail2.png
    ./.tools/tutorial-conversion/obj/texture/gstand-detail3.dds
    ./.tools/tutorial-conversion/obj/texture/gstand-detail3.png
    ./.tools/tutorial-conversion/obj/texture/gstand-detail3_MAP_rough3.png
    ./.tools/tutorial-conversion/obj/texture/gstand-detail3_NM.dds
    ./.tools/tutorial-conversion/obj/texture/gstand-detail3_NM.png
    ./.tools/tutorial-conversion/obj/texture/itpine_E.dds
    ./.tools/tutorial-conversion/obj/texture/itpine_E.png
    ./.tools/tutorial-conversion/obj/texture/ivy_hi.dds
    ./.tools/tutorial-conversion/obj/texture/ivy_hi.png
    ./.tools/tutorial-conversion/obj/texture/lapdisplay.dds
    ./.tools/tutorial-conversion/obj/texture/lapdisplay.png
    ./.tools/tutorial-conversion/obj/texture/ledwall.dds
    ./.tools/tutorial-conversion/obj/texture/ledwall.png
    ./.tools/tutorial-conversion/obj/texture/marshall-box.dds
    ./.tools/tutorial-conversion/obj/texture/marshall-box.png
    ./.tools/tutorial-conversion/obj/texture/marshall-box_MAP_rough4.png
    ./.tools/tutorial-conversion/obj/texture/marshallA.dds
    ./.tools/tutorial-conversion/obj/texture/marshallA.png
    ./.tools/tutorial-conversion/obj/texture/metal_dt_1.dds
    ./.tools/tutorial-conversion/obj/texture/metal_dt_1.png
    ./.tools/tutorial-conversion/obj/texture/metal_plate_roof.dds
    ./.tools/tutorial-conversion/obj/texture/metal_plate_roof.png
    ./.tools/tutorial-conversion/obj/texture/metal_plate_tile_1.dds
    ./.tools/tutorial-conversion/obj/texture/metal_plate_tile_1.png
    ./.tools/tutorial-conversion/obj/texture/mid_NM.dds
    ./.tools/tutorial-conversion/obj/texture/mid_NM.png
    ./.tools/tutorial-conversion/obj/texture/misc.dds
    ./.tools/tutorial-conversion/obj/texture/misc.png
    ./.tools/tutorial-conversion/obj/texture/net-alpha.dds
    ./.tools/tutorial-conversion/obj/texture/net-alpha.png
    ./.tools/tutorial-conversion/obj/texture/panels.dds
    ./.tools/tutorial-conversion/obj/texture/panels.png
    ./.tools/tutorial-conversion/obj/texture/paratie1.dds
    ./.tools/tutorial-conversion/obj/texture/paratie1.png
    ./.tools/tutorial-conversion/obj/texture/pine_leaf.dds
    ./.tools/tutorial-conversion/obj/texture/pine_leaf.png
    ./.tools/tutorial-conversion/obj/texture/pitlane-build1.dds
    ./.tools/tutorial-conversion/obj/texture/pitlane-build1.png
    ./.tools/tutorial-conversion/obj/texture/podium.dds
    ./.tools/tutorial-conversion/obj/texture/podium.png
    ./.tools/tutorial-conversion/obj/texture/pole1.dds
    ./.tools/tutorial-conversion/obj/texture/pole1.png
    ./.tools/tutorial-conversion/obj/texture/red-pitlane.dds
    ./.tools/tutorial-conversion/obj/texture/red-pitlane.png
    ./.tools/tutorial-conversion/obj/texture/red.dds
    ./.tools/tutorial-conversion/obj/texture/red.png
    ./.tools/tutorial-conversion/obj/texture/road-concrete-ext.dds
    ./.tools/tutorial-conversion/obj/texture/road-concrete-ext.png
    ./.tools/tutorial-conversion/obj/texture/roof-tile_D.dds
    ./.tools/tutorial-conversion/obj/texture/roof-tile_D.png
    ./.tools/tutorial-conversion/obj/texture/roof-tile_MAP_rough1.png
    ./.tools/tutorial-conversion/obj/texture/roof-tile_NM.dds
    ./.tools/tutorial-conversion/obj/texture/roof-tile_NM.png
    ./.tools/tutorial-conversion/obj/texture/sand_base.dds
    ./.tools/tutorial-conversion/obj/texture/sand_base.png
    ./.tools/tutorial-conversion/obj/texture/sand_base_MAP_rough1.png
    ./.tools/tutorial-conversion/obj/texture/sand_base_NM.dds
    ./.tools/tutorial-conversion/obj/texture/sand_base_NM.png
    ./.tools/tutorial-conversion/obj/texture/sat2B.dds
    ./.tools/tutorial-conversion/obj/texture/sat2B.png
    ./.tools/tutorial-conversion/obj/texture/semaphore.dds
    ./.tools/tutorial-conversion/obj/texture/semaphore.png
    ./.tools/tutorial-conversion/obj/texture/series logo.dds
    ./.tools/tutorial-conversion/obj/texture/series logo.png
    ./.tools/tutorial-conversion/obj/texture/slow-curb.dds
    ./.tools/tutorial-conversion/obj/texture/slow-curb.png
    ./.tools/tutorial-conversion/obj/texture/slow-curb_MAP_rough2.png
    ./.tools/tutorial-conversion/obj/texture/slow-curb_NM.dds
    ./.tools/tutorial-conversion/obj/texture/slow-curb_NM.png
    ./.tools/tutorial-conversion/obj/texture/sp_bumps.png
    ./.tools/tutorial-conversion/obj/texture/sponsors 2.dds
    ./.tools/tutorial-conversion/obj/texture/sponsors 2.png
    ./.tools/tutorial-conversion/obj/texture/sponsors-ground1.dds
    ./.tools/tutorial-conversion/obj/texture/sponsors-ground1.png
    ./.tools/tutorial-conversion/obj/texture/sponsors.dds
    ./.tools/tutorial-conversion/obj/texture/sponsors.png
    ./.tools/tutorial-conversion/obj/texture/struc-green-ext.dds
    ./.tools/tutorial-conversion/obj/texture/struc-green-ext.png
    ./.tools/tutorial-conversion/obj/texture/structures-alpha.dds
    ./.tools/tutorial-conversion/obj/texture/structures-alpha.png
    ./.tools/tutorial-conversion/obj/texture/structures-base.dds
    ./.tools/tutorial-conversion/obj/texture/structures-base.png
    ./.tools/tutorial-conversion/obj/texture/structures-base_MAP_rough2.png
    ./.tools/tutorial-conversion/obj/texture/stucco_1.dds
    ./.tools/tutorial-conversion/obj/texture/stucco_1.png
    ./.tools/tutorial-conversion/obj/texture/tarmac_green.dds
    ./.tools/tutorial-conversion/obj/texture/tarmac_green.png
    ./.tools/tutorial-conversion/obj/texture/tent-fabric1.dds
    ./.tools/tutorial-conversion/obj/texture/tent-fabric1.png
    ./.tools/tutorial-conversion/obj/texture/time-tower.dds
    ./.tools/tutorial-conversion/obj/texture/time-tower.png
    ./.tools/tutorial-conversion/obj/texture/tower spons.dds
    ./.tools/tutorial-conversion/obj/texture/tower spons.png
    ./.tools/tutorial-conversion/obj/texture/towerdisplay.dds
    ./.tools/tutorial-conversion/obj/texture/towerdisplay.png
    ./.tools/tutorial-conversion/obj/texture/trap_detail.dds
    ./.tools/tutorial-conversion/obj/texture/trap_detail.png
    ./.tools/tutorial-conversion/obj/texture/tree_shadow.dds
    ./.tools/tutorial-conversion/obj/texture/tree_shadow.png
    ./.tools/tutorial-conversion/obj/texture/trees2G.dds
    ./.tools/tutorial-conversion/obj/texture/trees2G.png
    ./.tools/tutorial-conversion/obj/texture/tyres_add2.dds
    ./.tools/tutorial-conversion/obj/texture/tyres_add2.png
    ./.tools/tutorial-conversion/obj/texture/walls1.dds
    ./.tools/tutorial-conversion/obj/texture/walls1.png
    ./.tools/tutorial-conversion/obj/texture/walls1_MAP_rough2.png
    ./.tools/tutorial-conversion/obj/texture/walls1_NM.dds
    ./.tools/tutorial-conversion/obj/texture/walls1_NM.png
    ./.tools/tutorial-conversion/obj/texture/whiteline.dds
    ./.tools/tutorial-conversion/obj/texture/whiteline.png
    ./.tools/tutorial-conversion/obj/texture/whiteline3.dds
    ./.tools/tutorial-conversion/obj/texture/whiteline3.png
    ./.tools/tutorial-conversion/obj/texture/whiteline4.dds
    ./.tools/tutorial-conversion/obj/texture/whiteline4.png
    ./.tools/wheels/a-chasis-tras.jpg
    ./.tools/wheels/b-ruedas-tras.jpg
    ./.tools/wheels/backup-antes-redondeo/RedBull-Drive.glb
    ./.tools/wheels/backup-antes-redondeo/RedBull-Drive.glb.import
    ./.tools/wheels/backup-antes-redondeo/SHA256SUMS
    ./.tools/wheels/backup-antes-redondeo/auditoria-antes.json
    ./.tools/wheels/backup-antes-redondeo/informe-redondeo.json
    ./.tools/wheels/body-map.log
    ./.tools/wheels/body-profile.log
    ./.tools/wheels/body-vs-wheels.log
    ./.tools/wheels/body_map.py
    ./.tools/wheels/body_profile.py
    ./.tools/wheels/body_vs_wheels.py
    ./.tools/wheels/bordes_libres.py
    ./.tools/wheels/buscar_rueda_limpia.py
    ./.tools/wheels/c-chasis-lat.jpg
    ./.tools/wheels/c2-fl-lado.jpg
    ./.tools/wheels/c2-lat.jpg
    ./.tools/wheels/c2-planta.jpg
    ./.tools/wheels/c2-rl-detras.jpg
    ./.tools/wheels/c2-rl-lado.jpg
    ./.tools/wheels/c2-tras.jpg
    ./.tools/wheels/car-crop.png
    ./.tools/wheels/car-zoom.png
    ./.tools/wheels/cobertura_angular.py
    ./.tools/wheels/d-chasis-3q.jpg
    ./.tools/wheels/d1-rueda.jpg
    ./.tools/wheels/d2-rueda-atras.jpg
    ./.tools/wheels/d3-lateral.jpg
    ./.tools/wheels/diag-traseras.json
    ./.tools/wheels/diag/lateral_baja.png
    ./.tools/wheels/diag/rueda_trasera.png
    ./.tools/wheels/diag/rueda_trasera_atras.png
    ./.tools/wheels/diag/trasera_baja.png
    ./.tools/wheels/diag_traseras.py
    ./.tools/wheels/diseccion_delantera.py
    ./.tools/wheels/dump-drive.log
    ./.tools/wheels/dump_glb.py
    ./.tools/wheels/e-todo-tras.jpg
    ./.tools/wheels/fix-wheels-report.json
    ./.tools/wheels/fix-wheels.log
    ./.tools/wheels/fix_redbull_wheels.py
    ./.tools/wheels/k-fl-detras.jpg
    ./.tools/wheels/k-fl-lado.jpg
    ./.tools/wheels/k-rl-detras.jpg
    ./.tools/wheels/k-rl-lado.jpg
    ./.tools/wheels/m1-tras-baja.jpg
    ./.tools/wheels/m3-rueda-rl.jpg
    ./.tools/wheels/m4-rueda-fl.jpg
    ./.tools/wheels/n0-chase.jpg
    ./.tools/wheels/n1-tras-baja.jpg
    ./.tools/wheels/n2-lateral.jpg
    ./.tools/wheels/n3-rueda-rl.jpg
    ./.tools/wheels/n4-rueda-fl.jpg
    ./.tools/wheels/p-fw-l.jpg
    ./.tools/wheels/p-rw-l.jpg
    ./.tools/wheels/p-rw-r.jpg
    ./.tools/wheels/parts/arcilla-lateral_baja.png
    ./.tools/wheels/parts/arcilla-planta.png
    ./.tools/wheels/parts/arcilla-rueda_delantera_izq_delante.png
    ./.tools/wheels/parts/arcilla-rueda_delantera_izq_detras.png
    ./.tools/wheels/parts/arcilla-rueda_delantera_izq_lado.png
    ./.tools/wheels/parts/arcilla-rueda_trasera_izq_delante.png
    ./.tools/wheels/parts/arcilla-rueda_trasera_izq_detras.png
    ./.tools/wheels/parts/arcilla-rueda_trasera_izq_lado.png
    ./.tools/wheels/parts/arcilla-trasera_baja.png
    ./.tools/wheels/parts/arcilla-tres_cuartos.png
    ./.tools/wheels/parts/material-rueda_delantera_izq_delante.png
    ./.tools/wheels/parts/material-rueda_delantera_izq_detras.png
    ./.tools/wheels/parts/material-rueda_delantera_izq_lado.png
    ./.tools/wheels/parts/material-rueda_trasera_izq_delante.png
    ./.tools/wheels/parts/material-rueda_trasera_izq_detras.png
    ./.tools/wheels/parts/material-rueda_trasera_izq_lado.png
    ./.tools/wheels/parts/rueda_delantera_izq_delante.png
    ./.tools/wheels/parts/rueda_delantera_izq_detras.png
    ./.tools/wheels/parts/rueda_delantera_izq_lado.png
    ./.tools/wheels/parts/rueda_trasera_izq_delante.png
    ./.tools/wheels/parts/rueda_trasera_izq_detras.png
    ./.tools/wheels/parts/rueda_trasera_izq_lado.png
    ./.tools/wheels/parts/solo_chasis-lateral_baja.png
    ./.tools/wheels/parts/solo_chasis-planta.png
    ./.tools/wheels/parts/solo_chasis-trasera_baja.png
    ./.tools/wheels/parts/solo_chasis-tres_cuartos.png
    ./.tools/wheels/parts/solo_ruedas-lateral_baja.png
    ./.tools/wheels/parts/solo_ruedas-planta.png
    ./.tools/wheels/parts/solo_ruedas-trasera_baja.png
    ./.tools/wheels/parts/solo_ruedas-tres_cuartos.png
    ./.tools/wheels/parts/todo-lateral_baja.png
    ./.tools/wheels/parts/todo-planta.png
    ./.tools/wheels/parts/todo-trasera_baja.png
    ./.tools/wheels/parts/todo-tres_cuartos.png
    ./.tools/wheels/perfil_ruedas.py
    ./.tools/wheels/probe-antes.log
    ./.tools/wheels/probe-despues.log
    ./.tools/wheels/probe-pose-fix.log
    ./.tools/wheels/probe.log
    ./.tools/wheels/probe_source_wheels.py
    ./.tools/wheels/ranuras_finas.py
    ./.tools/wheels/rebuild-report.json
    ./.tools/wheels/rebuild_redbull.py
    ./.tools/wheels/regression-run.log
    ./.tools/wheels/regression.sh
    ./.tools/wheels/render/antes-hoja.html
    ./.tools/wheels/render/antes-hoja.jpg
    ./.tools/wheels/render/antes-traseras/wheel_fl-bajo-tres-cuartos.png
    ./.tools/wheels/render/antes-traseras/wheel_fl-banda.png
    ./.tools/wheels/render/antes-traseras/wheel_fl-cara-exterior.png
    ./.tools/wheels/render/antes-traseras/wheel_fl-cara-interior.png
    ./.tools/wheels/render/antes-traseras/wheel_fl-tres-cuartos.png
    ./.tools/wheels/render/antes-traseras/wheel_rl-bajo-tres-cuartos.png
    ./.tools/wheels/render/antes-traseras/wheel_rl-banda.png
    ./.tools/wheels/render/antes-traseras/wheel_rl-cara-exterior.png
    ./.tools/wheels/render/antes-traseras/wheel_rl-cara-interior.png
    ./.tools/wheels/render/antes-traseras/wheel_rl-tres-cuartos.png
    ./.tools/wheels/render/antes-traseras/wheel_rr-bajo-tres-cuartos.png
    ./.tools/wheels/render/antes-traseras/wheel_rr-banda.png
    ./.tools/wheels/render/antes-traseras/wheel_rr-cara-exterior.png
    ./.tools/wheels/render/antes-traseras/wheel_rr-cara-interior.png
    ./.tools/wheels/render/antes-traseras/wheel_rr-tres-cuartos.png
    ./.tools/wheels/render/antes/wheel_fl-bajo-tres-cuartos.png
    ./.tools/wheels/render/antes/wheel_fl-banda.png
    ./.tools/wheels/render/antes/wheel_fl-cara-exterior.png
    ./.tools/wheels/render/antes/wheel_fl-cara-interior.png
    ./.tools/wheels/render/antes/wheel_fl-tres-cuartos.png
    ./.tools/wheels/render/antes/wheel_rl-bajo-tres-cuartos.png
    ./.tools/wheels/render/antes/wheel_rl-banda.png
    ./.tools/wheels/render/antes/wheel_rl-cara-exterior.png
    ./.tools/wheels/render/antes/wheel_rl-cara-interior.png
    ./.tools/wheels/render/antes/wheel_rl-pieza0-bajo-tres-cuartos.png
    ./.tools/wheels/render/antes/wheel_rl-pieza0-banda.png
    ./.tools/wheels/render/antes/wheel_rl-pieza0-cara-exterior.png
    ./.tools/wheels/render/antes/wheel_rl-pieza0-cara-interior.png
    ./.tools/wheels/render/antes/wheel_rl-pieza0-tres-cuartos.png
    ./.tools/wheels/render/antes/wheel_rl-tres-cuartos.png
    ./.tools/wheels/render/comparativa-hoja.html
    ./.tools/wheels/render/comparativa-hoja.jpg
    ./.tools/wheels/render/comparativa-rr.html
    ./.tools/wheels/render/comparativa-rr.jpg
    ./.tools/wheels/render/comparativa-traseras.html
    ./.tools/wheels/render/comparativa-traseras.jpg
    ./.tools/wheels/render/despues-traseras/wheel_fl-bajo-tres-cuartos.png
    ./.tools/wheels/render/despues-traseras/wheel_fl-banda.png
    ./.tools/wheels/render/despues-traseras/wheel_fl-cara-exterior.png
    ./.tools/wheels/render/despues-traseras/wheel_fl-cara-interior.png
    ./.tools/wheels/render/despues-traseras/wheel_fl-tres-cuartos.png
    ./.tools/wheels/render/despues-traseras/wheel_fr-bajo-tres-cuartos.png
    ./.tools/wheels/render/despues-traseras/wheel_fr-banda.png
    ./.tools/wheels/render/despues-traseras/wheel_fr-cara-exterior.png
    ./.tools/wheels/render/despues-traseras/wheel_fr-cara-interior.png
    ./.tools/wheels/render/despues-traseras/wheel_fr-tres-cuartos.png
    ./.tools/wheels/render/despues-traseras/wheel_rl-bajo-tres-cuartos.png
    ./.tools/wheels/render/despues-traseras/wheel_rl-banda.png
    ./.tools/wheels/render/despues-traseras/wheel_rl-cara-exterior.png
    ./.tools/wheels/render/despues-traseras/wheel_rl-cara-interior.png
    ./.tools/wheels/render/despues-traseras/wheel_rl-tres-cuartos.png
    ./.tools/wheels/render/despues-traseras/wheel_rr-bajo-tres-cuartos.png
    ./.tools/wheels/render/despues-traseras/wheel_rr-banda.png
    ./.tools/wheels/render/despues-traseras/wheel_rr-cara-exterior.png
    ./.tools/wheels/render/despues-traseras/wheel_rr-cara-interior.png
    ./.tools/wheels/render/despues-traseras/wheel_rr-tres-cuartos.png
    ./.tools/wheels/render/material-hoja.html
    ./.tools/wheels/render/material-hoja.jpg
    ./.tools/wheels/render/seccion-hoja.html
    ./.tools/wheels/render/seccion-hoja.jpg
    ./.tools/wheels/render/seccion2-hoja.html
    ./.tools/wheels/render/seccion2-hoja.jpg
    ./.tools/wheels/render_piezas.py
    ./.tools/wheels/reparacion-traseras.json
    ./.tools/wheels/reparar_traseras.py
    ./.tools/wheels/s-reposo-frontal.jpg
    ./.tools/wheels/s-reposo-lateral.jpg
    ./.tools/wheels/s-reposo-trasera.jpg
    ./.tools/wheels/s-reposo-trasera_baja.jpg
    ./.tools/wheels/s-reposo-tres_cuartos.jpg
    ./.tools/wheels/t-chasis-3q-zoom.jpg
    ./.tools/wheels/t-chasis-planta.jpg
    ./.tools/wheels/t-chasis-tras-zoom.jpg
    ./.tools/wheels/traseras-reparadas.glb
    ./.tools/wheels/v-acelerando.png
    ./.tools/wheels/v-carroad.png
    ./.tools/wheels/v-tras-conducir.png
    ./.tools/wheels/ver_la_goma.py
    ./.tools/wheels/views/marcha-camara_del_juego.png
    ./.tools/wheels/views/marcha-frontal.png
    ./.tools/wheels/views/marcha-lateral.png
    ./.tools/wheels/views/marcha-planta.png
    ./.tools/wheels/views/marcha-rueda_delantera_izq.png
    ./.tools/wheels/views/marcha-rueda_trasera_izq.png
    ./.tools/wheels/views/marcha-trasera.png
    ./.tools/wheels/views/marcha-trasera_baja.png
    ./.tools/wheels/views/marcha-tres_cuartos.png
    ./.tools/wheels/views/reposo-camara_del_juego.png
    ./.tools/wheels/views/reposo-frontal.png
    ./.tools/wheels/views/reposo-lateral.png
    ./.tools/wheels/views/reposo-planta.png
    ./.tools/wheels/views/reposo-rueda_delantera_izq.png
    ./.tools/wheels/views/reposo-rueda_trasera_izq.png
    ./.tools/wheels/views/reposo-trasera.png
    ./.tools/wheels/views/reposo-trasera_baja.png
    ./.tools/wheels/views/reposo-tres_cuartos.png
    ./.tools/wheels/w-chase.jpg
    ./.tools/wheels/w-fl.jpg
    ./.tools/wheels/w-planta.jpg
    ./.tools/wheels/w-rl.jpg
    ./.tools/wheels/wheel-geometry.log
    ./.tools/wheels/wheel_geometry.py
    ./.tools/wheels/wheels-beads.json
    ./.tools/wheels/z-fl.png
    ./.tools/wheels/z-fr.png
    ./.tools/wheels/z-rl.png
    ./.tools/wheels/z-rr.png
    ./.tools/wheels/z2-3q.jpg
    ./.tools/wheels/z2-lat.jpg
    ./.tools/wheels/z2-tras.jpg
    ./.tools/wheels/z2-trasbaja.jpg
    ./AC2026/.DS_Store
    ./AC2026/.gitignore
    ./AC2026/cat.rar
    ./AC2026/suz.7z
    ./ENTREGA-FINAL.md
    ./VehiclePrototypes/.DS_Store
    ./VehiclePrototypes/.gdignore
    ./VehiclePrototypes/Alpine/production/Alpine.blend
    ./VehiclePrototypes/Alpine/production/Alpine.fbx
    ./VehiclePrototypes/Alpine/production/Alpine.glb
    ./VehiclePrototypes/Alpine/source/Alpine.blend
    ./VehiclePrototypes/Alpine/source/Alpine.fbx
    ./VehiclePrototypes/Alpine/source/Alpine.glb
    ./VehiclePrototypes/AstonMartin/production/AstonMartin.blend
    ./VehiclePrototypes/AstonMartin/production/AstonMartin.fbx
    ./VehiclePrototypes/AstonMartin/production/AstonMartin.glb
    ./VehiclePrototypes/AstonMartin/source/AstonMartin.blend
    ./VehiclePrototypes/AstonMartin/source/AstonMartin.fbx
    ./VehiclePrototypes/AstonMartin/source/AstonMartin.glb
    ./VehiclePrototypes/Audi/production/Audi.blend
    ./VehiclePrototypes/Audi/production/Audi.fbx
    ./VehiclePrototypes/Audi/production/Audi.glb
    ./VehiclePrototypes/Audi/source/Audi.blend
    ./VehiclePrototypes/Audi/source/Audi.fbx
    ./VehiclePrototypes/Audi/source/Audi.glb
    ./VehiclePrototypes/Cadillac/.DS_Store
    ./VehiclePrototypes/Cadillac/production/Cadilac.fbx
    ./VehiclePrototypes/Cadillac/production/Cadillac.blend
    ./VehiclePrototypes/Cadillac/production/Cadillac.glb
    ./VehiclePrototypes/Cadillac/production/legacy/Cadillac_pre-meshy2.blend
    ./VehiclePrototypes/Cadillac/source/.DS_Store
    ./VehiclePrototypes/Cadillac/source/Cadillac.blend
    ./VehiclePrototypes/Cadillac/source/Cadillac.fbx
    ./VehiclePrototypes/Cadillac/source/Cadillac.glb
    ./VehiclePrototypes/FLEET_SOURCE_MANIFEST.json
    ./VehiclePrototypes/Ferrari/production/Ferrari.fbx
    ./VehiclePrototypes/Ferrari/production/Ferrari.glb
    ./VehiclePrototypes/Ferrari/production/Ferrrari.blend
    ./VehiclePrototypes/Ferrari/reports/INSPECTION_REPORT.md
    ./VehiclePrototypes/Ferrari/source/Ferrari.fbx
    ./VehiclePrototypes/Ferrari/source/Ferrari.glb
    ./VehiclePrototypes/Ferrari/source/Ferrrari.blend
    ./VehiclePrototypes/Haas/production/Haas.blend
    ./VehiclePrototypes/Haas/production/Haas.fbx
    ./VehiclePrototypes/Haas/production/Haas.glb
    ./VehiclePrototypes/Haas/source/Haas.blend
    ./VehiclePrototypes/Haas/source/Haas.fbx
    ./VehiclePrototypes/Haas/source/Haas.glb
    ./VehiclePrototypes/McLaren/production/McLaren.blend
    ./VehiclePrototypes/McLaren/production/McLaren.fbx
    ./VehiclePrototypes/McLaren/production/McLaren.glb
    ./VehiclePrototypes/McLaren/source/McLaren.blend
    ./VehiclePrototypes/McLaren/source/McLaren.fbx
    ./VehiclePrototypes/McLaren/source/McLaren.glb
    ./VehiclePrototypes/Mercedes/.DS_Store
    ./VehiclePrototypes/Mercedes/production/merche.blend
    ./VehiclePrototypes/Mercedes/production/merche.fbx
    ./VehiclePrototypes/Mercedes/production/merche.glb
    ./VehiclePrototypes/Mercedes/source/merche.blend
    ./VehiclePrototypes/Mercedes/source/merche.fbx
    ./VehiclePrototypes/Mercedes/source/merche.glb
    ./VehiclePrototypes/RacingBulls/production/RacingBulls.blend
    ./VehiclePrototypes/RacingBulls/production/RacingBulls.fbx
    ./VehiclePrototypes/RacingBulls/production/RacingBulls.glb
    ./VehiclePrototypes/RacingBulls/source/RacingBulls.blend
    ./VehiclePrototypes/RacingBulls/source/RacingBulls.fbx
    ./VehiclePrototypes/RacingBulls/source/RacingBulls.glb
    ./VehiclePrototypes/RedBull/production/RedBull.blend
    ./VehiclePrototypes/RedBull/production/RedBull.fbx
    ./VehiclePrototypes/RedBull/production/RedBull.glb
    ./VehiclePrototypes/RedBull/source/RedBull.blend
    ./VehiclePrototypes/RedBull/source/RedBull.fbx
    ./VehiclePrototypes/RedBull/source/RedBull.glb
    ./VehiclePrototypes/TestResults/_view_tmp/00_C_voxel6mm_menosX.jpg
    ./VehiclePrototypes/TestResults/_view_tmp/00_base_color.jpg
    ./VehiclePrototypes/TestResults/_view_tmp/00_f1_wheel_l0_masX.jpg
    ./VehiclePrototypes/TestResults/_view_tmp/00_f1_wheel_l0_menosX.jpg
    ./VehiclePrototypes/TestResults/_view_tmp/01_C_voxel6mm_34.jpg
    ./VehiclePrototypes/TestResults/_view_tmp/01_f1_wheel_l0_34.jpg
    ./VehiclePrototypes/TestResults/_view_tmp/01_metallic.jpg
    ./VehiclePrototypes/TestResults/_view_tmp/02_B_voxel4mm_menosX.jpg
    ./VehiclePrototypes/TestResults/_view_tmp/02_f1_wheel_l0_masX.jpg
    ./VehiclePrototypes/TestResults/_view_tmp/02_f1_wheel_l1_masX.jpg
    ./VehiclePrototypes/TestResults/_view_tmp/02_f1_wheel_l1_menosX.jpg
    ./VehiclePrototypes/TestResults/_view_tmp/02_roughness.jpg
    ./VehiclePrototypes/TestResults/_view_tmp/03_A_soldada3_menosX.jpg
    ./VehiclePrototypes/TestResults/_view_tmp/03_f1_wheel_l2_masX.jpg
    ./VehiclePrototypes/TestResults/_view_tmp/03_f1_wheel_l2_menosX.jpg
    ./VehiclePrototypes/TestResults/_view_tmp/04_f1_wheel_l2_34.jpg
    ./VehiclePrototypes/TestResults/vista_lods.html
    ./VehiclePrototypes/TestResults/vista_remesh.html
    ./VehiclePrototypes/TestResults/vista_rueda_tex.html
    ./VehiclePrototypes/TestResults/vista_tex_wheel.html
    ./VehiclePrototypes/TestResults/vista_wheel_diag.html
    ./VehiclePrototypes/TestResults/vista_wheel_mat.html
    ./VehiclePrototypes/TestResults/wheel_asset/f1_wheel_l0_34.png
    ./VehiclePrototypes/TestResults/wheel_asset/f1_wheel_l0_masX.png
    ./VehiclePrototypes/TestResults/wheel_asset/f1_wheel_l0_menosX.png
    ./VehiclePrototypes/TestResults/wheel_asset/f1_wheel_l1_34.png
    ./VehiclePrototypes/TestResults/wheel_asset/f1_wheel_l1_masX.png
    ./VehiclePrototypes/TestResults/wheel_asset/f1_wheel_l1_menosX.png
    ./VehiclePrototypes/TestResults/wheel_asset/f1_wheel_l2_34.png
    ./VehiclePrototypes/TestResults/wheel_asset/f1_wheel_l2_masX.png
    ./VehiclePrototypes/TestResults/wheel_asset/f1_wheel_l2_menosX.png
    ./VehiclePrototypes/TestResults/wheel_diag/f1_wheel_l0_34.png
    ./VehiclePrototypes/TestResults/wheel_diag/f1_wheel_l0_masX.png
    ./VehiclePrototypes/TestResults/wheel_diag/f1_wheel_l0_menosX.png
    ./VehiclePrototypes/TestResults/wheel_mat/f1_wheel_l0_34.png
    ./VehiclePrototypes/TestResults/wheel_mat/f1_wheel_l0_masX.png
    ./VehiclePrototypes/TestResults/wheel_mat/f1_wheel_l0_menosX.png
    ./VehiclePrototypes/TestResults/wheel_mat/f1_wheel_l1_34.png
    ./VehiclePrototypes/TestResults/wheel_mat/f1_wheel_l1_masX.png
    ./VehiclePrototypes/TestResults/wheel_mat/f1_wheel_l1_menosX.png
    ./VehiclePrototypes/TestResults/wheel_mat/f1_wheel_l2_34.png
    ./VehiclePrototypes/TestResults/wheel_mat/f1_wheel_l2_masX.png
    ./VehiclePrototypes/TestResults/wheel_mat/f1_wheel_l2_menosX.png
    ./VehiclePrototypes/TestResults/wheel_mesh/soldada_2400_34.png
    ./VehiclePrototypes/TestResults/wheel_mesh/soldada_2400_menosX.png
    ./VehiclePrototypes/TestResults/wheel_mesh/soldada_6000_34.png
    ./VehiclePrototypes/TestResults/wheel_mesh/soldada_6000_menosX.png
    ./VehiclePrototypes/TestResults/wheel_remesh/A_soldada3_34.png
    ./VehiclePrototypes/TestResults/wheel_remesh/A_soldada3_menosX.png
    ./VehiclePrototypes/TestResults/wheel_remesh/B_voxel4mm_34.png
    ./VehiclePrototypes/TestResults/wheel_remesh/B_voxel4mm_menosX.png
    ./VehiclePrototypes/TestResults/wheel_remesh/C_voxel6mm_34.png
    ./VehiclePrototypes/TestResults/wheel_remesh/C_voxel6mm_menosX.png
    ./VehiclePrototypes/TestResults/wheel_tex/f1_wheel_l0_34.png
    ./VehiclePrototypes/TestResults/wheel_tex/f1_wheel_l0_menosX.png
    ./VehiclePrototypes/TestResults/wheel_tex/f1_wheel_l1_34.png
    ./VehiclePrototypes/TestResults/wheel_tex/f1_wheel_l1_menosX.png
    ./VehiclePrototypes/TestResults/wheel_tex/f1_wheel_l2_34.png
    ./VehiclePrototypes/TestResults/wheel_tex/f1_wheel_l2_menosX.png
    ./VehiclePrototypes/VEHICLE_INTEGRATION_REPORT.md
    ./VehiclePrototypes/Williams/production/Williams.blend
    ./VehiclePrototypes/Williams/production/Williams.fbx
    ./VehiclePrototypes/Williams/production/Williams.glb
    ./VehiclePrototypes/Williams/source/Williams.blend
    ./VehiclePrototypes/Williams/source/Williams.fbx
    ./VehiclePrototypes/Williams/source/Williams.glb
    ./VehiclePrototypes/_backup_fill_20260921/alpine/build.json
    ./VehiclePrototypes/_backup_fill_20260921/alpine/model.fbx
    ./VehiclePrototypes/_backup_fill_20260921/alpine/model_lod1.fbx
    ./VehiclePrototypes/_backup_fill_20260921/alpine/model_lod2.fbx
    ./VehiclePrototypes/_backup_fill_20260921/astonmartin/build.json
    ./VehiclePrototypes/_backup_fill_20260921/astonmartin/model.fbx
    ./VehiclePrototypes/_backup_fill_20260921/astonmartin/model_lod1.fbx
    ./VehiclePrototypes/_backup_fill_20260921/astonmartin/model_lod2.fbx
    ./VehiclePrototypes/_backup_fill_20260921/audi/build.json
    ./VehiclePrototypes/_backup_fill_20260921/audi/model.fbx
    ./VehiclePrototypes/_backup_fill_20260921/audi/model_lod1.fbx
    ./VehiclePrototypes/_backup_fill_20260921/audi/model_lod2.fbx
    ./VehiclePrototypes/_backup_fill_20260921/cadillac/build.json
    ./VehiclePrototypes/_backup_fill_20260921/cadillac/model.fbx
    ./VehiclePrototypes/_backup_fill_20260921/cadillac/model_lod1.fbx
    ./VehiclePrototypes/_backup_fill_20260921/cadillac/model_lod2.fbx
    ./VehiclePrototypes/_backup_fill_20260921/ferrari/build.json
    ./VehiclePrototypes/_backup_fill_20260921/ferrari/model.fbx
    ./VehiclePrototypes/_backup_fill_20260921/ferrari/model_lod1.fbx
    ./VehiclePrototypes/_backup_fill_20260921/ferrari/model_lod2.fbx
    ./VehiclePrototypes/_backup_fill_20260921/haas/build.json
    ./VehiclePrototypes/_backup_fill_20260921/haas/model.fbx
    ./VehiclePrototypes/_backup_fill_20260921/haas/model_lod1.fbx
    ./VehiclePrototypes/_backup_fill_20260921/haas/model_lod2.fbx
    ./VehiclePrototypes/_backup_fill_20260921/mclaren/build.json
    ./VehiclePrototypes/_backup_fill_20260921/mclaren/model.fbx
    ./VehiclePrototypes/_backup_fill_20260921/mclaren/model_lod1.fbx
    ./VehiclePrototypes/_backup_fill_20260921/mclaren/model_lod2.fbx
    ./VehiclePrototypes/_backup_fill_20260921/mercedes/build.json
    ./VehiclePrototypes/_backup_fill_20260921/mercedes/model.fbx
    ./VehiclePrototypes/_backup_fill_20260921/mercedes/model_lod1.fbx
    ./VehiclePrototypes/_backup_fill_20260921/mercedes/model_lod2.fbx
    ./VehiclePrototypes/_backup_fill_20260921/racingbulls/build.json
    ./VehiclePrototypes/_backup_fill_20260921/racingbulls/model.fbx
    ./VehiclePrototypes/_backup_fill_20260921/racingbulls/model_lod1.fbx
    ./VehiclePrototypes/_backup_fill_20260921/racingbulls/model_lod2.fbx
    ./VehiclePrototypes/_backup_fill_20260921/redbull/build.json
    ./VehiclePrototypes/_backup_fill_20260921/redbull/model.fbx
    ./VehiclePrototypes/_backup_fill_20260921/redbull/model_lod1.fbx
    ./VehiclePrototypes/_backup_fill_20260921/redbull/model_lod2.fbx
    ./VehiclePrototypes/_backup_fill_20260921/williams/build.json
    ./VehiclePrototypes/_backup_fill_20260921/williams/model.fbx
    ./VehiclePrototypes/_backup_fill_20260921/williams/model_lod1.fbx
    ./VehiclePrototypes/_backup_fill_20260921/williams/model_lod2.fbx
    ./VehiclePrototypes/audit/big_ferrari_source_3q_frontal.jpg
    ./VehiclePrototypes/audit/big_ferrari_source_lateral.jpg
    ./VehiclePrototypes/audit/big_v7_car_3q_frontal.jpg
    ./VehiclePrototypes/audit/big_v7_car_lateral.jpg
    ./VehiclePrototypes/audit/cmp2_nuevo_car_3q_frontal.jpg
    ./VehiclePrototypes/audit/cmp2_nuevo_car_3q_trasero.jpg
    ./VehiclePrototypes/audit/cmp2_nuevo_car_lateral.jpg
    ./VehiclePrototypes/audit/cmp2_nuevo_wheel_fl.jpg
    ./VehiclePrototypes/audit/cmp2_prod_wheel_fl.jpg
    ./VehiclePrototypes/audit/cmp_ferrari_source_3q_frontal.jpg
    ./VehiclePrototypes/audit/cmp_ferrari_source_3q_trasero.jpg
    ./VehiclePrototypes/audit/cmp_ferrari_source_lateral.jpg
    ./VehiclePrototypes/audit/cmp_v7_car_3q_frontal.jpg
    ./VehiclePrototypes/audit/cmp_v7_car_3q_trasero.jpg
    ./VehiclePrototypes/audit/cmp_v7_car_lateral.jpg
    ./VehiclePrototypes/audit/f_3q_del.jpg
    ./VehiclePrototypes/audit/f_3q_tra.jpg
    ./VehiclePrototypes/audit/f_carrera.jpg
    ./VehiclePrototypes/audit/f_carrera_cerca.jpg
    ./VehiclePrototypes/audit/f_rueda_bl_fuera.jpg
    ./VehiclePrototypes/audit/f_rueda_bl_montada.jpg
    ./VehiclePrototypes/audit/f_rueda_fl_fuera.jpg
    ./VehiclePrototypes/audit/f_rueda_fl_montada.jpg
    ./VehiclePrototypes/audit/ferrari_ref.jpg
    ./VehiclePrototypes/audit/ferrari_source_3q_frontal.jpg
    ./VehiclePrototypes/audit/ferrari_source_3q_frontal.png
    ./VehiclePrototypes/audit/ferrari_source_3q_trasero.jpg
    ./VehiclePrototypes/audit/ferrari_source_3q_trasero.png
    ./VehiclePrototypes/audit/ferrari_source_lateral.jpg
    ./VehiclePrototypes/audit/ferrari_source_lateral.png
    ./VehiclePrototypes/audit/fl_alpine_3q.jpg
    ./VehiclePrototypes/audit/fl_alpine_carrera.jpg
    ./VehiclePrototypes/audit/fl_astonmartin_3q.jpg
    ./VehiclePrototypes/audit/fl_astonmartin_carrera.jpg
    ./VehiclePrototypes/audit/fl_audi_3q.jpg
    ./VehiclePrototypes/audit/fl_audi_carrera.jpg
    ./VehiclePrototypes/audit/fl_cadillac_3q.jpg
    ./VehiclePrototypes/audit/fl_cadillac_carrera.jpg
    ./VehiclePrototypes/audit/fl_ferrari_3q.jpg
    ./VehiclePrototypes/audit/fl_ferrari_carrera.jpg
    ./VehiclePrototypes/audit/fl_haas_3q.jpg
    ./VehiclePrototypes/audit/fl_haas_carrera.jpg
    ./VehiclePrototypes/audit/fl_mclaren_3q.jpg
    ./VehiclePrototypes/audit/fl_mclaren_carrera.jpg
    ./VehiclePrototypes/audit/fl_mercedes_3q.jpg
    ./VehiclePrototypes/audit/fl_mercedes_carrera.jpg
    ./VehiclePrototypes/audit/fl_racingbulls_3q.jpg
    ./VehiclePrototypes/audit/fl_racingbulls_carrera.jpg
    ./VehiclePrototypes/audit/fl_redbull_3q.jpg
    ./VehiclePrototypes/audit/fl_redbull_carrera.jpg
    ./VehiclePrototypes/audit/fl_williams_3q.jpg
    ./VehiclePrototypes/audit/fl_williams_carrera.jpg
    ./VehiclePrototypes/audit/galeria.html
    ./VehiclePrototypes/audit/hoja_Alpine.jpg
    ./VehiclePrototypes/audit/hoja_AstonMartin.jpg
    ./VehiclePrototypes/audit/hoja_Audi.jpg
    ./VehiclePrototypes/audit/hoja_Cadillac.jpg
    ./VehiclePrototypes/audit/hoja_Ferrari.jpg
    ./VehiclePrototypes/audit/hoja_Haas.jpg
    ./VehiclePrototypes/audit/hoja_McLaren.jpg
    ./VehiclePrototypes/audit/hoja_RacingBulls.jpg
    ./VehiclePrototypes/audit/hoja_RedBull.jpg
    ./VehiclePrototypes/audit/hoja_Williams.jpg
    ./VehiclePrototypes/audit/prod_wheel_fl.jpg
    ./VehiclePrototypes/audit/prod_wheel_fr.jpg
    ./VehiclePrototypes/audit/prod_wheel_rl.jpg
    ./VehiclePrototypes/audit/prod_wheel_rr.jpg
    ./VehiclePrototypes/audit/s_alpine.jpg
    ./VehiclePrototypes/audit/s_astonmartin.jpg
    ./VehiclePrototypes/audit/s_audi.jpg
    ./VehiclePrototypes/audit/s_cadillac.jpg
    ./VehiclePrototypes/audit/s_ferrari.jpg
    ./VehiclePrototypes/audit/s_haas.jpg
    ./VehiclePrototypes/audit/s_mclaren.jpg
    ./VehiclePrototypes/audit/s_mercedes.jpg
    ./VehiclePrototypes/audit/s_racingbulls.jpg
    ./VehiclePrototypes/audit/s_redbull.jpg
    ./VehiclePrototypes/audit/s_williams.jpg
    ./VehiclePrototypes/audit/src_wheel_fl.jpg
    ./VehiclePrototypes/audit/src_wheel_fr.jpg
    ./VehiclePrototypes/audit/src_wheel_rl.jpg
    ./VehiclePrototypes/audit/src_wheel_rr.jpg
    ./VehiclePrototypes/audit/w_wheel_3q.jpg
    ./VehiclePrototypes/audit/w_wheel_borde.jpg
    ./VehiclePrototypes/audit/w_wheel_lado_-X.jpg
    ./VehiclePrototypes/audit/w_wheel_mirando_+X.jpg
    ./VehiclePrototypes/audit/wheel_ref.jpg
    ./VehiclePrototypes/refs/ferrari_ref.png
    ./VehiclePrototypes/refs/ferrari_v7.glb
    ./VehiclePrototypes/refs/ferrari_v7_textures/base_color.png
    ./VehiclePrototypes/refs/ferrari_v7_textures/metallic.png
    ./VehiclePrototypes/refs/ferrari_v7_textures/normal.png
    ./VehiclePrototypes/refs/ferrari_v7_textures/roughness.png
    ./VehiclePrototypes/refs/wheel_ref.png
    ./VehiclePrototypes/tools/audit_all_blend.py
    ./VehiclePrototypes/tools/audit_blend.py
    ./VehiclePrototypes/tools/audit_glb.py
    ./VehiclePrototypes/tools/audit_parts.py
    ./VehiclePrototypes/tools/audit_structure.py
    ./VehiclePrototypes/tools/contact_sheet.py
    ./VehiclePrototypes/tools/fleet_validate.py
    ./VehiclePrototypes/tools/make_viewer.py
    ./VehiclePrototypes/tools/make_wheel.py
    ./VehiclePrototypes/tools/probe_cadillac.py
    ./VehiclePrototypes/tools/probe_fbx_wheels.py
    ./VehiclePrototypes/tools/probe_nose.py
    ./VehiclePrototypes/tools/probe_src_wheel.py
    ./VehiclePrototypes/tools/probe_wheel_asset.py
    ./VehiclePrototypes/tools/probe_wheel_bottom.py
    ./VehiclePrototypes/tools/probe_wheel_fill.py
    ./VehiclePrototypes/tools/probe_wheel_mesh.py
    ./VehiclePrototypes/tools/probe_wheel_profile.py
    ./VehiclePrototypes/tools/probe_wheel_remesh.py
    ./VehiclePrototypes/tools/probe_wheel_split.py
    ./VehiclePrototypes/tools/produce_fleet.py
    ./VehiclePrototypes/tools/render_audit.py
    ./VehiclePrototypes/tools/render_prod.py
    ./VehiclePrototypes/tools/render_wheel_mat.py
    ./VehiclePrototypes/tools/render_wheel_textured.py
    ./VehiclePrototypes/tools/render_wheels.py
    ./VehiclePrototypes/tools/run_batch.sh
    ./VehiclePrototypes/tools/update_fleet_json.py
    ./VehiclePrototypes/tools/wheel_lods.py
    ./VehiclePrototypes/wheel/f1_wheel.fbx
    ./VehiclePrototypes/wheel/f1_wheel_build.json
    ./VehiclePrototypes/wheel/f1_wheel_l0.fbx
    ./VehiclePrototypes/wheel/f1_wheel_l1.fbx
    ./VehiclePrototypes/wheel/f1_wheel_l2.fbx
    ./VehiclePrototypes/wheel/meshy_wheel.glb
    ./VehiclePrototypes/wheel/meshy_wheel_textures/base_color.png
    ./VehiclePrototypes/wheel/meshy_wheel_textures/metallic.png
    ./VehiclePrototypes/wheel/meshy_wheel_textures/normal.png
    ./VehiclePrototypes/wheel/meshy_wheel_textures/roughness.png
    ./VehiclePrototypes/wheel/wheel_asset.json
    ./assets/BarcelonaMoto-Tutorial.glb
    ./assets/BarcelonaMoto-Tutorial.glb.import
    ./assets/BarcelonaMoto-Tutorial_3dt3B.png
    ./assets/BarcelonaMoto-Tutorial_3dt3B.png.import
    ./assets/BarcelonaMoto-Tutorial_Barcellona_Box_A.png
    ./assets/BarcelonaMoto-Tutorial_Barcellona_Box_A.png.import
    ./assets/BarcelonaMoto-Tutorial_BricksWall.png
    ./assets/BarcelonaMoto-Tutorial_BricksWall.png.import
    ./assets/BarcelonaMoto-Tutorial_BricksWall_MAP.png
    ./assets/BarcelonaMoto-Tutorial_BricksWall_MAP.png.import
    ./assets/BarcelonaMoto-Tutorial_BricksWall_NM.png
    ./assets/BarcelonaMoto-Tutorial_BricksWall_NM.png.import
    ./assets/BarcelonaMoto-Tutorial_Concrete_wall.png
    ./assets/BarcelonaMoto-Tutorial_Concrete_wall.png.import
    ./assets/BarcelonaMoto-Tutorial_DRIVER_Face.png
    ./assets/BarcelonaMoto-Tutorial_DRIVER_Face.png.import
    ./assets/BarcelonaMoto-Tutorial_DRIVER_Suit.png
    ./assets/BarcelonaMoto-Tutorial_DRIVER_Suit.png.import
    ./assets/BarcelonaMoto-Tutorial_Garage_Colour.png
    ./assets/BarcelonaMoto-Tutorial_Garage_Colour.png.import
    ./assets/BarcelonaMoto-Tutorial_GrandStand_base.png
    ./assets/BarcelonaMoto-Tutorial_GrandStand_base.png.import
    ./assets/BarcelonaMoto-Tutorial_GrandStand_base_MAP.png
    ./assets/BarcelonaMoto-Tutorial_GrandStand_base_MAP.png.import
    ./assets/BarcelonaMoto-Tutorial_GrandStand_base_NMW5.png
    ./assets/BarcelonaMoto-Tutorial_GrandStand_base_NMW5.png.import
    ./assets/BarcelonaMoto-Tutorial_Lights_Emissive_DIF.png
    ./assets/BarcelonaMoto-Tutorial_Lights_Emissive_DIF.png.import
    ./assets/BarcelonaMoto-Tutorial_Props_PITLANE.png
    ./assets/BarcelonaMoto-Tutorial_Props_PITLANE.png.import
    ./assets/BarcelonaMoto-Tutorial_Props_PITLANE_NM.png
    ./assets/BarcelonaMoto-Tutorial_Props_PITLANE_NM.png.import
    ./assets/BarcelonaMoto-Tutorial_Wood_plank.png
    ./assets/BarcelonaMoto-Tutorial_Wood_plank.png.import
    ./assets/BarcelonaMoto-Tutorial_Wood_plank_MAP.png
    ./assets/BarcelonaMoto-Tutorial_Wood_plank_MAP.png.import
    ./assets/BarcelonaMoto-Tutorial_Wood_plank_NM.png
    ./assets/BarcelonaMoto-Tutorial_Wood_plank_NM.png.import
    ./assets/BarcelonaMoto-Tutorial_ac_crew.png
    ./assets/BarcelonaMoto-Tutorial_ac_crew.png.import
    ./assets/BarcelonaMoto-Tutorial_ao-ext.png
    ./assets/BarcelonaMoto-Tutorial_ao-ext.png.import
    ./assets/BarcelonaMoto-Tutorial_asd.png
    ./assets/BarcelonaMoto-Tutorial_asd.png.import
    ./assets/BarcelonaMoto-Tutorial_asph-red.png
    ./assets/BarcelonaMoto-Tutorial_asph-red.png.import
    ./assets/BarcelonaMoto-Tutorial_asph-red_MAP.png
    ./assets/BarcelonaMoto-Tutorial_asph-red_MAP.png.import
    ./assets/BarcelonaMoto-Tutorial_asph-white.png
    ./assets/BarcelonaMoto-Tutorial_asph-white.png.import
    ./assets/BarcelonaMoto-Tutorial_asph_updt.png
    ./assets/BarcelonaMoto-Tutorial_asph_updt.png.import
    ./assets/BarcelonaMoto-Tutorial_background_B.png
    ./assets/BarcelonaMoto-Tutorial_background_B.png.import
    ./assets/BarcelonaMoto-Tutorial_barcelona t10.png
    ./assets/BarcelonaMoto-Tutorial_barcelona t10.png.import
    ./assets/BarcelonaMoto-Tutorial_bark.png
    ./assets/BarcelonaMoto-Tutorial_bark.png.import
    ./assets/BarcelonaMoto-Tutorial_barrier.png
    ./assets/BarcelonaMoto-Tutorial_barrier.png.import
    ./assets/BarcelonaMoto-Tutorial_box-fence.png
    ./assets/BarcelonaMoto-Tutorial_box-fence.png.import
    ./assets/BarcelonaMoto-Tutorial_box-numbers.png
    ./assets/BarcelonaMoto-Tutorial_box-numbers.png.import
    ./assets/BarcelonaMoto-Tutorial_box-wall.png
    ./assets/BarcelonaMoto-Tutorial_box-wall.png.import
    ./assets/BarcelonaMoto-Tutorial_box-wall_MAP.png
    ./assets/BarcelonaMoto-Tutorial_box-wall_MAP.png.import
    ./assets/BarcelonaMoto-Tutorial_box-wall_NM.png
    ./assets/BarcelonaMoto-Tutorial_box-wall_NM.png.import
    ./assets/BarcelonaMoto-Tutorial_box1.png
    ./assets/BarcelonaMoto-Tutorial_box1.png.import
    ./assets/BarcelonaMoto-Tutorial_box1_MAP.png
    ./assets/BarcelonaMoto-Tutorial_box1_MAP.png.import
    ./assets/BarcelonaMoto-Tutorial_box1_NM.png
    ./assets/BarcelonaMoto-Tutorial_box1_NM.png.import
    ./assets/BarcelonaMoto-Tutorial_branch5.png
    ./assets/BarcelonaMoto-Tutorial_branch5.png.import
    ./assets/BarcelonaMoto-Tutorial_bridge2.png
    ./assets/BarcelonaMoto-Tutorial_bridge2.png.import
    ./assets/BarcelonaMoto-Tutorial_bridge2_MAP.png
    ./assets/BarcelonaMoto-Tutorial_bridge2_MAP.png.import
    ./assets/BarcelonaMoto-Tutorial_bridge2_NM.png
    ./assets/BarcelonaMoto-Tutorial_bridge2_NM.png.import
    ./assets/BarcelonaMoto-Tutorial_bridge_1B_MAP.png
    ./assets/BarcelonaMoto-Tutorial_bridge_1B_MAP.png.import
    ./assets/BarcelonaMoto-Tutorial_bridge_1_d.png
    ./assets/BarcelonaMoto-Tutorial_bridge_1_d.png.import
    ./assets/BarcelonaMoto-Tutorial_bridge_normal.png
    ./assets/BarcelonaMoto-Tutorial_bridge_normal.png.import
    ./assets/BarcelonaMoto-Tutorial_carpet-base_MAP.png
    ./assets/BarcelonaMoto-Tutorial_carpet-base_MAP.png.import
    ./assets/BarcelonaMoto-Tutorial_carpet.png
    ./assets/BarcelonaMoto-Tutorial_carpet.png.import
    ./assets/BarcelonaMoto-Tutorial_carpet_NM.png
    ./assets/BarcelonaMoto-Tutorial_carpet_NM.png.import
    ./assets/BarcelonaMoto-Tutorial_catalunya spons1.png
    ./assets/BarcelonaMoto-Tutorial_catalunya spons1.png.import
    ./assets/BarcelonaMoto-Tutorial_clockdisplay.png
    ./assets/BarcelonaMoto-Tutorial_clockdisplay.png.import
    ./assets/BarcelonaMoto-Tutorial_commissario_NEW.png
    ./assets/BarcelonaMoto-Tutorial_commissario_NEW.png.import
    ./assets/BarcelonaMoto-Tutorial_concrete_box.png
    ./assets/BarcelonaMoto-Tutorial_concrete_box.png.import
    ./assets/BarcelonaMoto-Tutorial_concrete_box_MAP.png
    ./assets/BarcelonaMoto-Tutorial_concrete_box_MAP.png.import
    ./assets/BarcelonaMoto-Tutorial_concrete_box_NM.png
    ./assets/BarcelonaMoto-Tutorial_concrete_box_NM.png.import
    ./assets/BarcelonaMoto-Tutorial_concrete_white_old_albedo2.png
    ./assets/BarcelonaMoto-Tutorial_concrete_white_old_albedo2.png.import
    ./assets/BarcelonaMoto-Tutorial_curb1_A.png
    ./assets/BarcelonaMoto-Tutorial_curb1_A.png.import
    ./assets/BarcelonaMoto-Tutorial_curb1_NM.png
    ./assets/BarcelonaMoto-Tutorial_curb1_NM.png.import
    ./assets/BarcelonaMoto-Tutorial_curb2.png
    ./assets/BarcelonaMoto-Tutorial_curb2.png.import
    ./assets/BarcelonaMoto-Tutorial_curb2_NM.png
    ./assets/BarcelonaMoto-Tutorial_curb2_NM.png.import
    ./assets/BarcelonaMoto-Tutorial_curb_typeB.png
    ./assets/BarcelonaMoto-Tutorial_curb_typeB.png.import
    ./assets/BarcelonaMoto-Tutorial_curb_typeB_NM.png
    ./assets/BarcelonaMoto-Tutorial_curb_typeB_NM.png.import
    ./assets/BarcelonaMoto-Tutorial_digitalflag.png
    ./assets/BarcelonaMoto-Tutorial_digitalflag.png.import
    ./assets/BarcelonaMoto-Tutorial_digitalflag_main_alb.png
    ./assets/BarcelonaMoto-Tutorial_digitalflag_main_alb.png.import
    ./assets/BarcelonaMoto-Tutorial_direction-villa.png
    ./assets/BarcelonaMoto-Tutorial_direction-villa.png.import
    ./assets/BarcelonaMoto-Tutorial_distanz.png
    ./assets/BarcelonaMoto-Tutorial_distanz.png.import
    ./assets/BarcelonaMoto-Tutorial_distanz_MAP.png
    ./assets/BarcelonaMoto-Tutorial_distanz_MAP.png.import
    ./assets/BarcelonaMoto-Tutorial_distanz_NM.png
    ./assets/BarcelonaMoto-Tutorial_distanz_NM.png.import
    ./assets/BarcelonaMoto-Tutorial_drs.png
    ./assets/BarcelonaMoto-Tutorial_drs.png.import
    ./assets/BarcelonaMoto-Tutorial_fences1.png
    ./assets/BarcelonaMoto-Tutorial_fences1.png.import
    ./assets/BarcelonaMoto-Tutorial_fences2.png
    ./assets/BarcelonaMoto-Tutorial_fences2.png.import
    ./assets/BarcelonaMoto-Tutorial_flat_NM.png
    ./assets/BarcelonaMoto-Tutorial_flat_NM.png.import
    ./assets/BarcelonaMoto-Tutorial_glass-box.png
    ./assets/BarcelonaMoto-Tutorial_glass-box.png.import
    ./assets/BarcelonaMoto-Tutorial_glass-name1.png
    ./assets/BarcelonaMoto-Tutorial_glass-name1.png.import
    ./assets/BarcelonaMoto-Tutorial_grail.png
    ./assets/BarcelonaMoto-Tutorial_grail.png.import
    ./assets/BarcelonaMoto-Tutorial_grail_MAP.png
    ./assets/BarcelonaMoto-Tutorial_grail_MAP.png.import
    ./assets/BarcelonaMoto-Tutorial_grail_NM.png
    ./assets/BarcelonaMoto-Tutorial_grail_NM.png.import
    ./assets/BarcelonaMoto-Tutorial_grass-brd-ext.png
    ./assets/BarcelonaMoto-Tutorial_grass-brd-ext.png.import
    ./assets/BarcelonaMoto-Tutorial_grass-brd3-F.png
    ./assets/BarcelonaMoto-Tutorial_grass-brd3-F.png.import
    ./assets/BarcelonaMoto-Tutorial_grass2_MAP.png
    ./assets/BarcelonaMoto-Tutorial_grass2_MAP.png.import
    ./assets/BarcelonaMoto-Tutorial_grass_base2.png
    ./assets/BarcelonaMoto-Tutorial_grass_base2.png.import
    ./assets/BarcelonaMoto-Tutorial_gravel.png
    ./assets/BarcelonaMoto-Tutorial_gravel.png.import
    ./assets/BarcelonaMoto-Tutorial_grille.png
    ./assets/BarcelonaMoto-Tutorial_grille.png.import
    ./assets/BarcelonaMoto-Tutorial_grille2.png
    ./assets/BarcelonaMoto-Tutorial_grille2.png.import
    ./assets/BarcelonaMoto-Tutorial_grille2_MAP.png
    ./assets/BarcelonaMoto-Tutorial_grille2_MAP.png.import
    ./assets/BarcelonaMoto-Tutorial_grille2_NM.png
    ./assets/BarcelonaMoto-Tutorial_grille2_NM.png.import
    ./assets/BarcelonaMoto-Tutorial_grille2_red.png
    ./assets/BarcelonaMoto-Tutorial_grille2_red.png.import
    ./assets/BarcelonaMoto-Tutorial_grille_MAP.png
    ./assets/BarcelonaMoto-Tutorial_grille_MAP.png.import
    ./assets/BarcelonaMoto-Tutorial_grille_NM.png
    ./assets/BarcelonaMoto-Tutorial_grille_NM.png.import
    ./assets/BarcelonaMoto-Tutorial_groove.png
    ./assets/BarcelonaMoto-Tutorial_groove.png.import
    ./assets/BarcelonaMoto-Tutorial_ground spons 2.png
    ./assets/BarcelonaMoto-Tutorial_ground spons 2.png.import
    ./assets/BarcelonaMoto-Tutorial_gstand-detail2.png
    ./assets/BarcelonaMoto-Tutorial_gstand-detail2.png.import
    ./assets/BarcelonaMoto-Tutorial_gstand-detail3.png
    ./assets/BarcelonaMoto-Tutorial_gstand-detail3.png.import
    ./assets/BarcelonaMoto-Tutorial_gstand-detail3_MAP.png
    ./assets/BarcelonaMoto-Tutorial_gstand-detail3_MAP.png.import
    ./assets/BarcelonaMoto-Tutorial_gstand-detail3_NM.png
    ./assets/BarcelonaMoto-Tutorial_gstand-detail3_NM.png.import
    ./assets/BarcelonaMoto-Tutorial_itpine_E.png
    ./assets/BarcelonaMoto-Tutorial_itpine_E.png.import
    ./assets/BarcelonaMoto-Tutorial_ivy_hi.png
    ./assets/BarcelonaMoto-Tutorial_ivy_hi.png.import
    ./assets/BarcelonaMoto-Tutorial_lapdisplay.png
    ./assets/BarcelonaMoto-Tutorial_lapdisplay.png.import
    ./assets/BarcelonaMoto-Tutorial_ledwall.png
    ./assets/BarcelonaMoto-Tutorial_ledwall.png.import
    ./assets/BarcelonaMoto-Tutorial_marshall-box.png
    ./assets/BarcelonaMoto-Tutorial_marshall-box.png.import
    ./assets/BarcelonaMoto-Tutorial_marshall-box_MAP.png
    ./assets/BarcelonaMoto-Tutorial_marshall-box_MAP.png.import
    ./assets/BarcelonaMoto-Tutorial_marshallA.png
    ./assets/BarcelonaMoto-Tutorial_marshallA.png.import
    ./assets/BarcelonaMoto-Tutorial_mid_NM.png
    ./assets/BarcelonaMoto-Tutorial_mid_NM.png.import
    ./assets/BarcelonaMoto-Tutorial_misc.png
    ./assets/BarcelonaMoto-Tutorial_misc.png.import
    ./assets/BarcelonaMoto-Tutorial_net-alpha.png
    ./assets/BarcelonaMoto-Tutorial_net-alpha.png.import
    ./assets/BarcelonaMoto-Tutorial_panels.png
    ./assets/BarcelonaMoto-Tutorial_panels.png.import
    ./assets/BarcelonaMoto-Tutorial_paratie1.png
    ./assets/BarcelonaMoto-Tutorial_paratie1.png.import
    ./assets/BarcelonaMoto-Tutorial_pine_leaf.png
    ./assets/BarcelonaMoto-Tutorial_pine_leaf.png.import
    ./assets/BarcelonaMoto-Tutorial_pitlane-build1.png
    ./assets/BarcelonaMoto-Tutorial_pitlane-build1.png.import
    ./assets/BarcelonaMoto-Tutorial_podium.png
    ./assets/BarcelonaMoto-Tutorial_podium.png.import
    ./assets/BarcelonaMoto-Tutorial_pole1.png
    ./assets/BarcelonaMoto-Tutorial_pole1.png.import
    ./assets/BarcelonaMoto-Tutorial_red-pitlane.png
    ./assets/BarcelonaMoto-Tutorial_red-pitlane.png.import
    ./assets/BarcelonaMoto-Tutorial_road-concrete-ext.png
    ./assets/BarcelonaMoto-Tutorial_road-concrete-ext.png.import
    ./assets/BarcelonaMoto-Tutorial_roof-tile_D.png
    ./assets/BarcelonaMoto-Tutorial_roof-tile_D.png.import
    ./assets/BarcelonaMoto-Tutorial_roof-tile_MAP.png
    ./assets/BarcelonaMoto-Tutorial_roof-tile_MAP.png.import
    ./assets/BarcelonaMoto-Tutorial_roof-tile_NM.png
    ./assets/BarcelonaMoto-Tutorial_roof-tile_NM.png.import
    ./assets/BarcelonaMoto-Tutorial_sand_base.png
    ./assets/BarcelonaMoto-Tutorial_sand_base.png.import
    ./assets/BarcelonaMoto-Tutorial_sand_base_MAP.png
    ./assets/BarcelonaMoto-Tutorial_sand_base_MAP.png.import
    ./assets/BarcelonaMoto-Tutorial_sand_base_NM.png
    ./assets/BarcelonaMoto-Tutorial_sand_base_NM.png.import
    ./assets/BarcelonaMoto-Tutorial_sat2B.png
    ./assets/BarcelonaMoto-Tutorial_sat2B.png.import
    ./assets/BarcelonaMoto-Tutorial_semaphore.png
    ./assets/BarcelonaMoto-Tutorial_semaphore.png.import
    ./assets/BarcelonaMoto-Tutorial_series logo.png
    ./assets/BarcelonaMoto-Tutorial_series logo.png.import
    ./assets/BarcelonaMoto-Tutorial_slow-curb.png
    ./assets/BarcelonaMoto-Tutorial_slow-curb.png.import
    ./assets/BarcelonaMoto-Tutorial_slow-curb_MAP.png
    ./assets/BarcelonaMoto-Tutorial_slow-curb_MAP.png.import
    ./assets/BarcelonaMoto-Tutorial_slow-curb_NM.png
    ./assets/BarcelonaMoto-Tutorial_slow-curb_NM.png.import
    ./assets/BarcelonaMoto-Tutorial_sp_bumps.png
    ./assets/BarcelonaMoto-Tutorial_sp_bumps.png.import
    ./assets/BarcelonaMoto-Tutorial_sponsors 2.png
    ./assets/BarcelonaMoto-Tutorial_sponsors 2.png.import
    ./assets/BarcelonaMoto-Tutorial_sponsors-ground1.png
    ./assets/BarcelonaMoto-Tutorial_sponsors-ground1.png.import
    ./assets/BarcelonaMoto-Tutorial_sponsors.png
    ./assets/BarcelonaMoto-Tutorial_sponsors.png.import
    ./assets/BarcelonaMoto-Tutorial_struc-green-ext.png
    ./assets/BarcelonaMoto-Tutorial_struc-green-ext.png.import
    ./assets/BarcelonaMoto-Tutorial_structures-alpha.png
    ./assets/BarcelonaMoto-Tutorial_structures-alpha.png.import
    ./assets/BarcelonaMoto-Tutorial_structures-base.png
    ./assets/BarcelonaMoto-Tutorial_structures-base.png.import
    ./assets/BarcelonaMoto-Tutorial_structures-base_MAP.png
    ./assets/BarcelonaMoto-Tutorial_structures-base_MAP.png.import
    ./assets/BarcelonaMoto-Tutorial_tarmac_green.png
    ./assets/BarcelonaMoto-Tutorial_tarmac_green.png.import
    ./assets/BarcelonaMoto-Tutorial_tent-fabric1.png
    ./assets/BarcelonaMoto-Tutorial_tent-fabric1.png.import
    ./assets/BarcelonaMoto-Tutorial_time-tower.png
    ./assets/BarcelonaMoto-Tutorial_time-tower.png.import
    ./assets/BarcelonaMoto-Tutorial_tower spons.png
    ./assets/BarcelonaMoto-Tutorial_tower spons.png.import
    ./assets/BarcelonaMoto-Tutorial_towerdisplay.png
    ./assets/BarcelonaMoto-Tutorial_towerdisplay.png.import
    ./assets/BarcelonaMoto-Tutorial_tree_shadow.png
    ./assets/BarcelonaMoto-Tutorial_tree_shadow.png.import
    ./assets/BarcelonaMoto-Tutorial_trees2G.png
    ./assets/BarcelonaMoto-Tutorial_trees2G.png.import
    ./assets/BarcelonaMoto-Tutorial_tyres_add2.png
    ./assets/BarcelonaMoto-Tutorial_tyres_add2.png.import
    ./assets/BarcelonaMoto-Tutorial_walls1.png
    ./assets/BarcelonaMoto-Tutorial_walls1.png.import
    ./assets/BarcelonaMoto-Tutorial_walls1_MAP.png
    ./assets/BarcelonaMoto-Tutorial_walls1_MAP.png.import
    ./assets/BarcelonaMoto-Tutorial_walls1_NM.png
    ./assets/BarcelonaMoto-Tutorial_walls1_NM.png.import
    ./assets/BarcelonaMoto-Tutorial_whiteline.png
    ./assets/BarcelonaMoto-Tutorial_whiteline.png.import
    ./assets/BarcelonaMoto-Tutorial_whiteline3.png
    ./assets/BarcelonaMoto-Tutorial_whiteline3.png.import
    ./assets/BarcelonaMoto-Tutorial_whiteline4.png
    ./assets/BarcelonaMoto-Tutorial_whiteline4.png.import
    ./assets/BarcelonaMoto.fast_lane.ai
    ./assets/BarcelonaMoto.ideal_line.ai
    ./assets/BarcelonaMoto.surfaces.json
    ./assets/RedBull-Drive.glb
    ./assets/RedBull-Drive.glb.import
    ./assets/RedBull-Drive_Image_0.jpg
    ./assets/RedBull-Drive_Image_0.jpg.import
    ./assets/RedBull-Drive_Image_1.jpg
    ./assets/RedBull-Drive_Image_1.jpg.import
    ./assets/RedBull-Drive_Image_2.jpg
    ./assets/RedBull-Drive_Image_2.jpg.import
    ./assets/RedBull-Drive_Image_3.jpg
    ./assets/RedBull-Drive_Image_3.jpg.import
    ./assets/RedBull.glb
    ./assets/RedBull.glb.import
    ./assets/RedBull.tscn
    ./assets/RedBull_Image_0.jpg
    ./assets/RedBull_Image_0.jpg.import
    ./assets/RedBull_Image_1.jpg
    ./assets/RedBull_Image_1.jpg.import
    ./assets/RedBull_Image_2.jpg
    ./assets/RedBull_Image_2.jpg.import
    ./assets/RedBull_Image_3.jpg
    ./assets/RedBull_Image_3.jpg.import
    ./assets/icon.svg
    ./assets/icon.svg.import
    ./build/android/F1OneShot-BarcelonaMoto.apk
    ./build/android/F1OneShot-BarcelonaMoto.apk.idsig
    ./build/android/reexport-check.apk.idsig
    ./build/android/stable/F1OneShot-BarcelonaMoto-20261013-1341.apk
    ./build/android/stable/F1OneShot-BarcelonaMoto-20261013-1341.apk.sha256
    ./build/android/stable/F1OneShot-BarcelonaMoto-pre-fix-20261013.apk
    ./build/android/stable/F1OneShot-BarcelonaMoto-pre-fix-20261013.apk.sha256
    ./export_presets.cfg
    ./project.godot
    ./scenes/race.tscn
    ./scripts/api_probe.gd
    ./scripts/api_probe.gd.uid
    ./scripts/barrier_impact_probe.gd
    ./scripts/barrier_impact_probe.gd.uid
    ./scripts/camera_nose_probe.gd
    ./scripts/camera_nose_probe.gd.uid
    ./scripts/camera_probe.gd
    ./scripts/camera_probe.gd.uid
    ./scripts/car_controller.gd
    ./scripts/car_controller.gd.uid
    ./scripts/car_delivery_probe.gd
    ./scripts/car_delivery_probe.gd.uid
    ./scripts/car_parts_probe.gd
    ./scripts/car_parts_probe.gd.uid
    ./scripts/car_wheel_probe.gd
    ./scripts/car_wheel_probe.gd.uid
    ./scripts/collision_inventory_probe.gd
    ./scripts/collision_inventory_probe.gd.uid
    ./scripts/controls_probe.gd
    ./scripts/controls_probe.gd.uid
    ./scripts/direct_dyn_probe.gd
    ./scripts/direct_dyn_probe.gd.uid
    ./scripts/drive_diag_probe.gd
    ./scripts/drive_diag_probe.gd.uid
    ./scripts/driving_probe.gd
    ./scripts/driving_probe.gd.uid
    ./scripts/dynamics_probe.gd
    ./scripts/dynamics_probe.gd.uid
    ./scripts/force_probe.gd
    ./scripts/force_probe.gd.uid
    ./scripts/fps_probe.gd
    ./scripts/fps_probe.gd.uid
    ./scripts/gltf_model.gd
    ./scripts/gltf_model.gd.uid
    ./scripts/headless_layout_check.gd
    ./scripts/headless_layout_check.gd.uid
    ./scripts/lap_probe.gd
    ./scripts/lap_probe.gd.uid
    ./scripts/line_curvature_probe.gd
    ./scripts/line_curvature_probe.gd.uid
    ./scripts/loader_probe.gd
    ./scripts/loader_probe.gd.uid
    ./scripts/offtrack_drive_probe.gd
    ./scripts/offtrack_drive_probe.gd.uid
    ./scripts/offtrack_mobility_probe.gd
    ./scripts/offtrack_mobility_probe.gd.uid
    ./scripts/offtrack_scan_probe.gd
    ./scripts/offtrack_scan_probe.gd.uid
    ./scripts/pbr_probe.gd
    ./scripts/pbr_probe.gd.uid
    ./scripts/race.gd
    ./scripts/race.gd.uid
    ./scripts/race_hud.gd
    ./scripts/race_hud.gd.uid
    ./scripts/render_probe.gd
    ./scripts/render_probe.gd.uid
    ./scripts/runtime_probe.gd
    ./scripts/runtime_probe.gd.uid
    ./scripts/steer_sign_probe.gd
    ./scripts/steer_sign_probe.gd.uid
    ./scripts/steering_probe.gd
    ./scripts/steering_probe.gd.uid
    ./scripts/surface_grip_probe.gd
    ./scripts/surface_grip_probe.gd.uid
    ./scripts/suspension_probe.gd
    ./scripts/suspension_probe.gd.uid
    ./scripts/touch_controls.gd
    ./scripts/touch_controls.gd.uid
    ./scripts/track_data.gd
    ./scripts/track_data.gd.uid
    ./scripts/track_probe.gd
    ./scripts/track_probe.gd.uid
    ./scripts/vehicle_normalize.py
    ./scripts/wall_visibility_probe.gd
    ./scripts/wall_visibility_probe.gd.uid
    ./scripts/wheel_diag_probe.gd
    ./scripts/wheel_diag_probe.gd.uid
    ./scripts/wheel_suspension.gd
    ./scripts/wheel_suspension.gd.uid
    ./verify.sh
