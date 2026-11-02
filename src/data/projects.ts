export interface ProjectItem {
  id: string;
  code: string;
  title: string;
  type: string;
  location: string;
  servicesProvided: string[];
  description: string;
  stats: { label: string; value: string }[];
  status: 'COMPLETED' | 'IN_PROGRESS' | 'SCHEDULED';
  imagePlaceholderColor: string;
  machineryDeployed: string[];
}

export const PROJECTS: ProjectItem[] = [
  {
    id: 'proj-01',
    code: 'PROJECT / 01',
    title: 'PARQUE SOLAR FOTOVOLTAICO HELIOS 120MW',
    type: 'Infraestructura Energética',
    location: 'Atacama Region',
    servicesProvided: ['SOLAR PROJECTS', 'EARTHMOVING', 'DRILLING'],
    description: 'Acondicionamiento masivo de 180 hectáreas, hincado de 28,000 postes de soporte y apertura de 45 km de canalizaciones eléctricas para parque solar.',
    stats: [
      { label: 'Capacidad Installed', value: '120 MW' },
      { label: 'Hectáreas Preparadas', value: '180 ha' },
      { label: 'Tiempo de Ejecución', value: '4.5 Meses' }
    ],
    status: 'COMPLETED',
    imagePlaceholderColor: '#15191C',
    machineryDeployed: ['Hincadora SL-500', 'Excavadora EX-350', 'Bobcat BC-120']
  },
  {
    id: 'proj-02',
    code: 'PROJECT / 02',
    title: 'PLATAFORMA LOGÍSTICA & CORREDOR VIAL INDUSTRIAL',
    type: 'Obra Civil & Movimiento de Tierra',
    location: 'Zona Industrial Norte',
    servicesProvided: ['EARTHMOVING', 'CONSTRUCTION', 'HEAVY EQUIPMENT'],
    description: 'Corte y compactación de 320,000 m³ de material para cimentación de centro de distribución de alta resistencia e interconexión vial.',
    stats: [
      { label: 'Volumen Removido', value: '320,000 m³' },
      { label: 'Superficie Pavimentada', value: '65,000 m²' },
      { label: 'Horas Maquinaria', value: '14,200 hrs' }
    ],
    status: 'COMPLETED',
    imagePlaceholderColor: '#252B2F',
    machineryDeployed: ['Excavadora EX-350', 'Retroexcavadora RX-480', 'Camiones Articulados']
  },
  {
    id: 'proj-03',
    code: 'PROJECT / 03',
    title: 'PILOTAJE PROFUNDO Y CIMENTACIÓN ESTRUCTURAL',
    type: 'Perforación Geotécnica',
    location: 'Valle Central',
    servicesProvided: ['DRILLING', 'EQUIPMENT RENTAL'],
    description: 'Ejecución de 140 pilotes de concreto de 1.2m de diámetro y 28m de profundidad para viaducto elevado de carga pesada.',
    stats: [
      { label: 'Pilotes Perforados', value: '140 Unidades' },
      { label: 'Profundidad Promedio', value: '28 m' },
      { label: 'Estrato', value: 'Roca Madre & Grava' }
    ],
    status: 'COMPLETED',
    imagePlaceholderColor: '#1A2126',
    machineryDeployed: ['Perforadora DR-800', 'Excavadora Support EX-350']
  },
  {
    id: 'proj-04',
    code: 'PROJECT / 04',
    title: 'DESARROLLO INFRAESTRUCTURA HÍDRICA Y CANALIZACIÓN',
    type: 'Infraestructura Hídrica',
    location: 'Región Andina',
    servicesProvided: ['EARTHMOVING', 'HEAVY EQUIPMENT', 'EQUIPMENT RENTAL'],
    description: 'Excavación de canal de alta capacidad de drenaje pluvial con revestimiento de enrocado para protección contra inundaciones.',
    stats: [
      { label: 'Longitud de Canal', value: '12.8 km' },
      { label: 'Enrocado Colocado', value: '42,000 Tn' },
      { label: 'Seguridad', value: '0 Incidentes' }
    ],
    status: 'IN_PROGRESS',
    imagePlaceholderColor: '#111518',
    machineryDeployed: ['Excavadoras Pesadas', 'Cargadores Frontales', 'Retroexcavadoras']
  }
];

export const BRAND_STANDARDS = [
  {
    code: '01',
    title: 'POWER',
    sub: 'Capacidad para trabajos exigentes.',
    desc: 'Equipos con reservas de potencia comprobadas en campo para operar sin descansos en condiciones extremas de carga y altitud.'
  },
  {
    code: '02',
    title: 'PRECISION',
    sub: 'Operaciones orientadas a resultados.',
    desc: 'Sistemas de guía láser y GPS de nivel milimétrico para optimizar consumos de diésel y tiempos de ciclo de trabajo.'
  },
  {
    code: '03',
    title: 'RELIABILITY',
    sub: 'Equipos y soluciones en los que puedes confiar.',
    desc: 'Mantenimiento preventivo computarizado con tasa de disponibilidad de flota superior al 98% en proyectos críticos.'
  },
  {
    code: '04',
    title: 'SCALE',
    sub: 'Preparados para proyectos de diferentes dimensiones.',
    desc: 'Infraestructura y logística integral para movilizar despliegues masivos de maquinaria en cuestión de horas.'
  }
];
