export interface MachineSpec {
  label: string;
  value: string;
}

export interface EquipmentItem {
  id: string;
  slug: string;
  name: string;
  code: string;
  category: 'hincadora' | 'bobcat' | 'servicios';
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
  model3DType: 'solar_rig' | 'bobcat' | 'excavator';
  image?: string;
}

export const FLEET_CATALOG: EquipmentItem[] = [
  {
    id: 'orvexa-hwl600r',
    slug: 'hincadora-orvexa-hwl600r',
    name: 'HINCADORA SOLAR HWL600R',
    image: '/images/fleet/hwl600r.png',
    code: 'HWL600R',
    category: 'hincadora',
    categoryLabel: 'Infraestructura Solar & Hincado',
    tagline: 'Hincado de alta velocidad y precisión milimétrica para proyectos solares fotovoltaicos.',
    powerRating: 'POWER / 01',
    description: 'Equipo especializado de última generación con chasis de orugas de alta estabilidad, torre hidráulica articulada y sistema de posicionamiento de alta precisión para la instalación masiva de perfiles y estructuras de soporte en parques solares.',
    detailedSpecs: [
      { label: 'Modelo', value: 'HWL600R' },
      { label: 'Peso Operativo', value: '6,200 kg' },
      { label: 'Potencia de Motor', value: '95 HP Diesel Turbo' },
      { label: 'Fuerza de Impacto', value: '1,350 Joules' },
      { label: 'Altura Máx. Hincado', value: '4.20 m' },
      { label: 'Rendimiento Promedio', value: '400 - 500 hincados / día' }
    ],
    applications: [
      'Hincado masivo de perfiles C, C+ y Z para rastreadores solares (trackers)',
      'Instalación de estructuras en parques fotovoltaicos de gran escala',
      'Perforación previa en terrenos rocosos o con estrato duro',
      'Hincado de postes de cerramiento perimetral de seguridad'
    ],
    availability: 'IMMEDIATE',
    operatingWeight: '6.2 Tn',
    enginePower: '95 HP',
    featured: true,
    model3DType: 'solar_rig'
  },
  {
    id: 'orvexa-bobcat-s650',
    slug: 'minicargador-bobcat',
    name: 'MINICARGADOR BOBCAT COMPACT',
    code: 'BOBCAT TURBO',
    category: 'bobcat',
    categoryLabel: 'Cargadores Compactos & Nivelación',
    tagline: 'Versatilidad, maniobrabilidad y potencia continua en acondicionamiento de obra.',
    powerRating: 'POWER / 02',
    description: 'Minicargador Bobcat de alto rendimiento con sistema hidráulico de alto flujo. Ideal para nivelación fina, limpieza rápida de frentes de trabajo, acarreo de materiales y apoyo operativo en el montaje de infraestructuras.',
    detailedSpecs: [
      { label: 'Peso Operativo', value: '3,800 kg' },
      { label: 'Potencia de Motor', value: '74 HP Turbo' },
      { label: 'Capacidad Nominal Carga', value: '1,220 kg' },
      { label: 'Ancho de Cucharon', value: '1.85 m' },
      { label: 'Flujo Hidráulico', value: 'High-Flow System' }
    ],
    applications: [
      'Nivelación y preparación de suelo pre y post hincado solar',
      'Acarreo rápido de estructuras, perfiles y material en sitio',
      'Limpieza y acondicionamiento de vías internas de parque solar',
      'Zanjado compacto e interconexión de canalizaciones'
    ],
    availability: 'IMMEDIATE',
    operatingWeight: '3.8 Tn',
    enginePower: '74 HP',
    bucketCapacity: '0.65 m³',
    featured: true,
    model3DType: 'bobcat'
  }
];
