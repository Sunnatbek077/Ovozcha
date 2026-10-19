Test resurslari uchun papka.

`Package.swift` test target'ida `resources: [.process("Resources")]` deb yozilgan,
shuning uchun bu papka mavjud bo'lishi shart — aks holda test target umuman
qurilmaydi ("The file Resources couldn't be opened").

Hozircha test uchun fayl kerak emas; papka shu sabab bo'sh turibdi.
