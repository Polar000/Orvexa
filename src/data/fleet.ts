export interface MachineSpec {
  label: string;
  value: string;
}

export interface EquipmentItem {
  id: string;
  slug: string;
  name: string;
  code: string;
  category: 'excavadora' | 'bobcat' | 'retroexcavadora' | 'perforadora' | 'solar';
  categoryLabel: string;
  tagline: string;
  powerRating: string; // e.g. "POWER / 01"
  description: string;
  detailedSpecs: MachineSpec[];
  applications: string[];
  availability: 'IMMEDIATE' | 'RESERVED' | 'IN_OPERATION';
  operatingWeight: string;
  enginePower: string;
  bucketCapacity?: string;
  maxDrillDepth?: string;
  featured: boolean;
  model3DType: 'excavator' | 'bobcat' | 'backhoe' | 'drill' | 'solar_rig';
}

export const FLEET_CATALOG: EquipmentItem[] = [
  {
    id: 'orvexa-ex350',
    slug: 'excavadora-orvexa-ex350',
    name: 'EXCAVADORA HEAVY-DUTY EX-350',
    code: 'EX-350 HD',
    category: 'excavadora',
    categoryLabel: 'Excavadoras de Gran Escala',
    tagline: 'Excavación profunda, movimiento de tierras y preparación intensiva de terrenos.',
    powerRating: 'POWER / 01',
    description: 'Diseñada para operar sin pausas en las condiciones geológicas más exigentes. Equipada con hidráulica de alta presión y monitoreo de telemetría en tiempo real.',
    detailedSpecs: [
      { label: 'Peso Operativo', value: '36,500 kg' },
      { label: 'Potencia de Motor', value: '315 HP @ 1,800 RPM' },
      { label: 'Capacidad de Cucharon', value: '2.4 m³' },
      { label: 'Profundidad Máx. Excavación', value: '7.85 m' },
      { label: 'Sistema Hidráulico', value: 'SmartFlow V2 High Pressure' }
    ],
    applications: [
      'Excavaciones para cimentación masiva',
      'Movimiento de tierras en minería e infraestructura',
      'Apertura de canalizaciones industriales',
      'Preparación de suelo para parques solares'
    ],
    availability: 'IMMEDIATE',
    operatingWeight: '36.5 Tn',
    enginePower: '315 HP',
    bucketCapacity: '2.4 m³',
    featured: true,
    model3DType: 'excavator'
  },
  {
    id: 'orvexa-bc120',
    slug: 'minicargador-bobcat-bc120',
    name: 'BOBCAT COMPACT LOADER BC-120',
    code: 'BC-120 TURBO',
    category: 'bobcat',
    categoryLabel: 'Cargadores Compactos',
    tagline: 'Maniobrabilidad milimétrica y máxima potencia en espacios reducidos.',
    powerRating: 'POWER / 02',
    description: 'Chasis reforzado y sistema de orugas de alta tracción para una respuesta rápida en trabajos urbanos y de nivelación de precisión.',
    detailedSpecs: [
      { label: 'Peso Operativo', value: '4,200 kg' },
      { label: 'Potencia de Motor', value: '92 HP Turbo' },
      { label: 'Capacidad de Carga', value: '1,450 kg' },
      { label: 'Ancho de Chasis', value: '1.85 m' }
    ],
    applications: [
      'Nivelación fina de terreno',
      'Limpieza rápida en frentes de obra',
      'Carga y abastecimiento en espacios confinados',
      'Soporte a montaje solar'
    ],
    availability: 'IMMEDIATE',
    operatingWeight: '4.2 Tn',
    enginePower: '92 HP',
    bucketCapacity: '0.65 m³',
    featured: true,
    model3DType: 'bobcat'
  },
  {
    id: 'orvexa-rx480',
    slug: 'retroexcavadora-orvexa-rx480',
    name: 'RETROEXCAVADORA VERSATILE RX-480',
    code: 'RX-480 DUAL',
    category: 'retroexcavadora',
    categoryLabel: 'Retroexcavadoras Mixtas',
    tagline: 'Doble funcionalidad extrema para excavación y carga continua.',
    powerRating: 'POWER / 03',
    description: 'Unidad multipropósito con brazo extensible hidráulico y cabina ergo-cinemática para optimizar ciclos de carga.',
    detailedSpecs: [
      { label: 'Peso Operativo', value: '9,800 kg' },
      { label: 'Potencia de Motor', value: '110 HP' },
      { label: 'Capacidad Cuchara Frontal', value: '1.2 m³' },
      { label: 'Profundidad de Zanja', value: '5.40 m' }
    ],
    applications: [
      'Zanjado rápido para tuberías y ductos',
      'Carga directa a camiones de volteo',
      'Obras civiles urbanas y viales',
      'Mantenimiento de vías de acceso'
    ],
    availability: 'IN_OPERATION',
    operatingWeight: '9.8 Tn',
    enginePower: '110 HP',
    bucketCapacity: '1.2 m³',
    featured: true,
    model3DType: 'backhoe'
  },
  {
    id: 'orvexa-dr800',
    slug: 'perforadora-orvexa-dr800',
    name: 'PERFORADORA ROTATIVA DR-800',
    code: 'DR-800 XTR',
    category: 'perforadora',
    categoryLabel: 'Equipos de Perforación',
    tagline: 'Penetración geológica de alta precisión para pilotaje y anclajes.',
    powerRating: 'POWER / 04',
    description: 'Torre de martillo rotativo pesado para micropilotes, cimentaciones profundas y perforación geotécnica avanzada.',
    detailedSpecs: [
      { label: 'Peso Operativo', value: '28,000 kg' },
      { label: 'Torque Máximo', value: '185 kNm' },
      { label: 'Profundidad Máx. Perforación', value: '32 m' },
      { label: 'Diámetro de Perforación', value: '400 - 1500 mm' }
    ],
    applications: [
      'Pilotaje para puentes y cimentaciones pesadas',
      'Hincado de perfiles solares',
      'Perforación en rocas de alta dureza',
      'Anclajes estructurales en laderas'
    ],
    availability: 'IMMEDIATE',
    operatingWeight: '28.0 Tn',
    enginePower: '275 HP',
    maxDrillDepth: '32 m',
    featured: true,
    model3DType: 'drill'
  },
  {
    id: 'orvexa-sl500',
    slug: 'equipo-solar-orvexa-sl500',
    name: 'HINCADORA SOLAR AUTOMATIZADA SL-500',
    code: 'SL-500 SOLAR',
    category: 'solar',
    categoryLabel: 'Infraestructura Solar',
    tagline: 'Hincado acelerado con posicionamiento GPS centimetral.',
    powerRating: 'POWER / 05',
    description: 'Optimizada específicamente para la instalación masiva de estructuras de soporte en huertos solares fotovoltaicos.',
    detailedSpecs: [
      { label: 'Peso Operativo', value: '5,600 kg' },
      { label: 'Energía de Impacto', value: '1,200 Joules' },
      { label: 'Precisión GPS RTK', value: '< 10 mm' },
      { label: 'Rendimiento Diario', value: 'Hasta 450 postes/día' }
    ],
    applications: [
      'Hincado de perfiles para rastreadores solares',
      'Apertura de microzanjas para cableado de media tensión',
      'Compactado de vías entre hileras solares'
    ],
    availability: 'IMMEDIATE',
    operatingWeight: '5.6 Tn',
    enginePower: '85 HP',
    featured: true,
    model3DType: 'solar_rig'
  }
];
