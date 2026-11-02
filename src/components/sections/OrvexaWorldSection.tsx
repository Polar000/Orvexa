"use client";

import React, { useState } from "react";
import { Layers, ShieldCheck, Sun, HardHat, Compass, Activity } from "lucide-react";

export function OrvexaWorldSection() {
  const [activeZone, setActiveZone] = useState<number>(0);

  const zones = [
    {
      id: "zone-1",
      code: "01 / EARTHMOVING & CUT",
      title: "Cortes & Movimiento de Tierra Masivo",
      desc: "Flota pesada equipada con GPS de doble antena para la remoción acelerada de sobrecapas y acondicionamiento de terrenos.",
      icon: Layers,
      stats: "320,000 m³ / mes",
      tag: "INFRAESTRUCTURA CIVIL"
    },
    {
      id: "zone-2",
      code: "02 / DRILLING & FOUNDATIONS",
      title: "Pilotaje Profundo y Estabilización",
      desc: "Torres de perforación para estratos rocosos, anclajes de ladera y cimentaciones de viaductos y torres solares.",
      icon: Compass,
      stats: "35m Profundidad Máx",
      tag: "INGENIERÍA GEOTÉCNICA"
    },
    {
      id: "zone-3",
      code: "03 / SOLAR PARK SETUP",
      title: "Adecuación para Huertos Fotovoltaicos",
      desc: "Hincado centimetral de postes para rastreadores solares y apertura de microzanjas para cableado de media tensión.",
      icon: Sun,
      stats: "450 Postes / día",
      tag: "ENERGÍA RENOVABLE"
    },
    {
      id: "zone-4",
      code: "04 / RENTAL & TELEMETRY",
      title: "Gestión Inteligente de Flota en Renta",
      desc: "Central de monitoreo con diagnóstico CANbus preventivo y asistencia de auxilio mecánico en campo 24/7.",
      icon: Activity,
      stats: "< 4 Hours SLA",
      tag: "OPERACIÓN CONTINUA"
    }
  ];

  return (
    <section className="relative w-full bg-[#080A0B] py-28 border-t border-[#252B2F]/60 overflow-hidden">
      <div className="max-w-7xl mx-auto px-6 md:px-12">
        {/* SECTION HEADER */}
        <div className="space-y-4 mb-16 max-w-3xl">
          <div className="inline-flex items-center gap-2 px-3 py-1 bg-[#15191C] border border-[#F5B800]/30 rounded text-[10px] font-mono tracking-widest text-[#F5B800] uppercase font-bold">
            <HardHat className="w-3.5 h-3.5" /> ORVEXA WORLD / OPERATIONAL SCALE
          </div>
          <h2 className="font-heading text-5xl sm:text-7xl font-extrabold text-[#F5F6F3] uppercase tracking-tighter">
            BUILT FOR SCALE.
          </h2>
          <p className="text-base sm:text-lg text-[#9BA2A6] font-sans font-light">
            Un ecosistema integral de maquinaria, ingeniería y despliegue logístico diseñado para operar simultáneamente en múltiples frentes de trabajo.
          </p>
        </div>

        {/* ISOMETRIC/INTERACTIVE SCENARIO GRID */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-center">
          {/* VISUAL INTERACTIVE SCENE CANVAS */}
          <div className="lg:col-span-7 bg-[#15191C] border border-[#252B2F] rounded-3xl p-8 min-h-[460px] relative flex flex-col justify-between overflow-hidden shadow-2xl bg-industrial-grid">
            {/* Ambient Background Glow */}
            <div className="absolute -top-20 -right-20 w-64 h-64 bg-[#F5B800]/10 rounded-full blur-3xl" />

            {/* Top Indicator */}
            <div className="flex items-center justify-between border-b border-[#252B2F] pb-4 z-10">
              <span className="text-xs font-mono text-[#F5B800] font-bold tracking-widest uppercase">
                SCENARIO INTERVIEW / {zones[activeZone].tag}
              </span>
              <span className="text-[10px] font-mono text-[#9BA2A6] uppercase">
                ACTIVE ZONE 0{activeZone + 1}
              </span>
            </div>

            {/* CENTER GRAPHIC CONCEPT DISPLAY */}
            <div className="my-auto py-8 z-10 space-y-6 text-center lg:text-left">
              <div className="w-16 h-16 bg-[#080A0B] border border-[#F5B800] rounded-2xl flex items-center justify-center yellow-glow mx-auto lg:mx-0">
                {React.createElement(zones[activeZone].icon, {
                  className: "w-8 h-8 text-[#F5B800]",
                })}
              </div>

              <div>
                <span className="text-xs font-mono text-[#F5B800] uppercase font-bold tracking-wider block">
                  {zones[activeZone].code}
                </span>
                <h3 className="font-heading text-3xl sm:text-4xl font-extrabold text-[#F5F6F3] uppercase tracking-tight mt-1">
                  {zones[activeZone].title}
                </h3>
                <p className="text-sm text-[#9BA2A6] max-w-lg mt-3 font-sans leading-relaxed">
                  {zones[activeZone].desc}
                </p>
              </div>

              <div className="inline-block bg-[#080A0B] border border-[#252B2F] px-4 py-2 rounded text-xs font-mono text-[#F5B800] font-bold">
                MÉTRICA DE CAPACIDAD: {zones[activeZone].stats}
              </div>
            </div>

            {/* BOTTOM ZONE TABS */}
            <div className="grid grid-cols-4 gap-2 pt-4 border-t border-[#252B2F] z-10">
              {zones.map((zone, idx) => (
                <button
                  key={zone.id}
                  onClick={() => setActiveZone(idx)}
                  className={`py-2 text-[10px] font-mono tracking-widest uppercase font-bold rounded border transition-all duration-300 ${
                    activeZone === idx
                      ? "bg-[#F5B800] text-[#080A0B] border-[#F5B800]"
                      : "bg-[#080A0B] text-[#9BA2A6] border-[#252B2F] hover:border-[#F5B800]/50"
                  }`}
                >
                  ZONA 0{idx + 1}
                </button>
              ))}
            </div>
          </div>

          {/* RIGHT ZONES SELECTOR LIST */}
          <div className="lg:col-span-5 space-y-4">
            {zones.map((zone, idx) => {
              const IconComp = zone.icon;
              const isSelected = activeZone === idx;
              return (
                <div
                  key={zone.id}
                  onClick={() => setActiveZone(idx)}
                  className={`p-6 rounded-2xl border transition-all duration-300 cursor-pointer ${
                    isSelected
                      ? "bg-[#15191C] border-[#F5B800] shadow-xl translate-x-2"
                      : "bg-[#080A0B]/60 border-[#252B2F] hover:bg-[#15191C]/50 hover:border-[#9BA2A6]/30"
                  }`}
                >
                  <div className="flex items-start gap-4">
                    <div
                      className={`p-3 rounded-xl border ${
                        isSelected
                          ? "bg-[#F5B800] text-[#080A0B] border-[#F5B800]"
                          : "bg-[#15191C] text-[#9BA2A6] border-[#252B2F]"
                      }`}
                    >
                      <IconComp className="w-6 h-6" />
                    </div>
                    <div className="space-y-1">
                      <span className="text-[10px] font-mono font-bold tracking-widest text-[#F5B800] uppercase block">
                        {zone.code}
                      </span>
                      <h4 className="text-lg font-heading font-bold text-[#F5F6F3] uppercase">
                        {zone.title}
                      </h4>
                      <p className="text-xs text-[#9BA2A6] line-clamp-2">
                        {zone.desc}
                      </p>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </section>
  );
}
