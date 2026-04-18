// platform-epf.test.mjs — Integration test: EPF build/dump roundtrip
// Requires: 1C platform (1cv8.exe) via .v8-project.json
// Steps: epf-init → epf-add-form → form-compile → epf-build → epf-dump

export const name = 'Сборка и разборка внешней обработки (roundtrip)';
export const setup = 'none';
export const requiresPlatform = true;

export const steps = [
  // ── 1. Create EPF ──
  {
    name: 'epf-init: пустая обработка',
    script: 'epf-init/scripts/init',
    args: { '-Name': 'RoundtripТест', '-SrcDir': '{workDir}' },
  },

  // ── 2. Add form to EPF ──
  {
    name: 'epf-add-form: форма обработки',
    script: 'epf-add-form/scripts/add-form',
    args: {
      '-ProcessorName': 'RoundtripТест',
      '-FormName': 'Форма',
      '-SrcDir': '{workDir}',
    },
  },

  {
    name: 'form-compile: наполнение формы обработки',
    script: 'form-compile/scripts/form-compile',
    input: {
      elements: [
        { input: 'ПутьКФайлу', path: 'ПутьКФайлу', title: 'Путь к файлу' },
        { button: 'Загрузить', title: 'Загрузить', action: 'Загрузить' },
      ],
      attributes: [
        { name: 'ПутьКФайлу', type: 'String' },
      ],
      commands: [
        { name: 'Загрузить', title: 'Загрузить' },
      ],
    },
    args: { '-OutputPath': '{workDir}/RoundtripТест/Forms/Форма/Ext/Form.xml', '-JsonPath': '{inputFile}' },
  },

  // ── 3. Build EPF binary ──
  {
    name: 'epf-build: сборка EPF',
    script: 'epf-build/scripts/epf-build',
    args: {
      '-V8Path': '{v8path}',
      '-SourceFile': '{workDir}/RoundtripТест.xml',
      '-OutputFile': '{workDir}/RoundtripТест.epf',
    },
  },

  // ── 4. Create temp DB for dump ──
  {
    name: 'db-create: временная ИБ для разборки',
    script: 'db-create/scripts/db-create',
    args: { '-V8Path': '{v8path}', '-InfoBasePath': '{workDir}/tmpdb' },
  },

  // ── 5. Dump back to XML ──
  {
    name: 'epf-dump: разборка EPF в XML',
    script: 'epf-dump/scripts/epf-dump',
    args: {
      '-V8Path': '{v8path}',
      '-InputFile': '{workDir}/RoundtripТест.epf',
      '-OutputDir': '{workDir}/roundtrip-dump',
      '-InfoBasePath': '{workDir}/tmpdb',
    },
  },
];
