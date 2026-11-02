export interface ServiceItem {
  id: string;
  code: string;
  title: string;
  subtitle: string;
  shortDesc: string;
  fullDesc: string;
  features: string[];
  metrics: { label: string; value: string }[];
  accentColor?: string;
}

export const SERVICES: ServiceItem[] = [
  {
    id: 'heavy-equipment',
    code: '01',
    title: 'HEAVY EQUIPMENT',
    subtitle: 'Flota pesada con altos estándares de mantenimiento',
    shortDesc: 'Venta, configuración y despliegue de maquinaria de alta tonelada para proyectos críticos.',
    fullDesc: 'Proveemos maquinaria pesada lista para operar en condiciones severas. Todas nuestras unidades cuentan con mantenimiento preventivo certificado y sistemas de telemetría remota para optimizar el rendimiento por hora.',
    features: [
      'Monitoreo satelital y de consumo diésel',
      'Operadores altamente capacitados y certificados',
      'Planes de contingencia y asistencia en sitio 24/7'
    ],
    metrics: [
      { label: 'Disponibilidad Operativa', value: '98.5%' },
      { label: 'Telemetría', value: 'GPS & CANbus' }
    ]
  },
  {
    id: 'equipment-rental',
    code: '02',
    title: 'EQUIPMENT RENTAL',
    subtitle: 'Modalidades flexibles por hora, día o proyecto completo',
    shortDesc: 'Alquiler con o sin operador, respaldado por logística de transporte propia.',
    fullDesc: 'Facilitamos esquemas de arrendamiento operativo que se adaptan al flujo de caja de tu obra. Transportamos los equipos directamente al punto de operación con trazabilidad total.',
    features: [
      'Contratos por día, mes o plazo extendido',
      'Mantenimiento correctivo en campo en menos de 4 horas',
      'Flete e ingravidez logística integrada'
    ],
    metrics: [
      { label: 'Tiempo de Respuesta', value: '< 4 Horas' },
      { label: 'Flota Garantizada', value: '100%' }
    ]
  },
  {
    id: 'earthmoving',
    code: '03',
    title: 'EARTHMOVING',
    subtitle: 'Corte, nivelación y acondicionamiento masivo de terreno',
    shortDesc: 'Movimiento de tierra masivo con control topográfico laser/GPS para cimentaciones de gran escala.',
    fullDesc: 'Ejecutamos volúmenes masivos de excavación y terraplenes con tecnología de control de maquinaria en 3D. Logramos cotas milimétricas con velocidad sin precedentes.',
    features: [
      'Control volumétrico por escáner LIDAR',
      'Flota de camiones articulados y volquetes',
      'Optimización de rutas de acarreo'
    ],
    metrics: [
      { label: 'Volumen Mensual', value: '150,000+ m³' },
      { label: 'Precisión Topográfica', value: '± 5 mm' }
    ]
  },
  {
    id: 'drilling',
    code: '04',
    title: 'DRILLING',
    subtitle: 'Perforación y pilotaje de alta precisión geológica',
    shortDesc: 'Soluciones de perforación geotécnica, pilotaje profundo y estabilización de taludes.',
    fullDesc: 'Contamos con perforadoras de última generación capaces de penetrar estratos rocosos de gran dureza para obras hidráulicas, cimentaciones pesadas y parques solares.',
    features: [
      'Pilotaje hasta 35 metros de profundidad',
      'Ensayos geológicos e inyección de lechada',
      'Sistemas de captura de polvo y bajo impacto ambiental'
    ],
    metrics: [
      { label: 'Profundidad Máx.', value: '35 Metros' },
      { label: 'Torque de Perforación', value: '185 kNm' }
    ]
  },
  {
    id: 'construction',
    code: '05',
    title: 'CONSTRUCTION',
    subtitle: 'Infraestructura civil y vial para sectores clave',
    shortDesc: 'Desarrollo de vías de acceso, plataformas industriales, drenajes y obra civil pesada.',
    fullDesc: 'Transformamos terrenos vírgenes en plataformas operativas completas con vías de alta resistencia, pavimentación y estructuras de concreto armado.',
    features: [
      'Obras viales de alta exigencia de carga',
      'Construcción de subestaciones y edificaciones técnicas',
      'Gestión integral de calidad bajo norma ISO 9001'
    ],
    metrics: [
      { label: 'Proyectos Ejecutados', value: '45+' },
      { label: 'Índice de Seguridad', value: 'Zero Harm' }
    ]
  },
  {
    id: 'solar-projects',
    code: '06',
    title: 'SOLAR PROJECTS',
    subtitle: 'Adecuación e infraestructura para proyectos fotovoltaicos',
    shortDesc: 'Adecuación de terrenos, hincado de perfiles solares y zanjado automatizado.',
    fullDesc: 'Especialistas en la fase de obra civil para parques solares de utilidad pública. Aceleramos los tiempos de hincado con maquinaria automatizada por GPS.',
    features: [
      'Hincado automatizado de estructuras fotovoltaicas',
      'Apertura de zanjas para cableado de MT/BT',
      'Adecuación de caminos perimetrales e interiores'
    ],
    metrics: [
      { label: 'Hincado Diario', value: '400+ Postes' },
      { label: 'MW Acondicionados', value: '250+ MW' }
    ]
  }
];
