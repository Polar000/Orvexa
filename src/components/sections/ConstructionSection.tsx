"use client";

import React from "react";
import { HardHat, Compass, Cpu, Layers } from "lucide-react";

export function ConstructionSection() {
  const steps = [
    {
      code: "01",
      title: "MOVIMIENTO DE TIERRAS",
      desc: "Remoción masiva de capote, nivelación topográfica con guía GPS y terraplenes de alta compacidad.",
      metric: "150,000+ m³ / mes",
    },
    {
      code: "02",
      title: "EXCAVACIÓN PROFUNDA",
      desc: "Zanjado técnico, fosos para cimentaciones de gran tonelaje y canales de derivación hídrica.",
      metric: "Hasta 8.0m Profundidad",
    },
    {
      code: "03",
      title: "PREPARACIÓN DE SUELO",
      desc: "Compactación estandarizada, estabilización con cal/cemento y pruebas de densidad Protor.",
      metric: "98% Proctor Modificado",
    },
    {
      code: "04",
      title: "CONSTRUCCIÓN CIVIL",
      desc: "Estructuras de concreto, plataformas industriales, pavimentación y pasos de agua de alto gálibo.",
      metric: "Normas ISO / ASTM",
    },
  ];

  return (
    <section className="relative w-full bg-[#080A0B] py-28 border-t border-[#252B2F]/60 overflow-hidden">
      <div className="max-w-7xl mx-auto px-6 md:px-12">
        {/* HEADER */}
        <div className="space-y-3 mb-16 max-w-2xl">
          <div className="inline-flex items-center gap-2 px-3 py-1 bg-[#15191C] border border-[#F5B800]/30 rounded text-[10px] font-mono tracking-widest text-[#F5F6F3] uppercase font-bold">
            <Compass className="w-3.5 h-3.5 text-[#F5B800]" /> INGENIERÍA Y CONSTRUCCIÓN DE INFRAESTRUCTURA
          </div>
          <h2 className="font-heading text-5xl sm:text-7xl font-extrabold text-[#F5F6F3] uppercase tracking-tighter">
            CIVIL ENGINEERING.
          </h2>
          <p className="text-base sm:text-lg text-[#9BA2A6] font-sans font-light">
            Metodología rigurosa de 4 fases para la ejecución de proyectos de infraestructura de alta complejidad.
          </p>
        </div>

        {/* 4 STAGE NUMBERED ENGINEERING PRESENTATION */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {steps.map((step) => (
            <div
              key={step.code}
              className="bg-[#15191C] border border-[#252B2F] rounded-2xl p-8 flex flex-col justify-between hover:border-[#F5B800] transition-all duration-300 group hover:-translate-y-1 shadow-xl"
            >
              <div className="space-y-6">
                <div className="flex items-center justify-between border-b border-[#252B2F] pb-4">
                  <span className="font-heading font-black text-4xl text-[#F5B800]">
                    {step.code}
                  </span>
                  <span className="text-[10px] font-mono text-[#9BA2A6] uppercase">
                    PHASE / 0{step.code}
                  </span>
                </div>

                <div>
                  <h3 className="font-heading text-xl font-bold text-[#F5F6F3] uppercase tracking-tight group-hover:text-[#F5B800] transition-colors">
                    {step.title}
                  </h3>
                  <p className="text-xs text-[#9BA2A6] mt-3 font-sans leading-relaxed">
                    {step.desc}
                  </p>
                </div>
              </div>

              <div className="pt-6 mt-6 border-t border-[#252B2F]">
                <span className="text-[10px] font-mono text-[#9BA2A6] uppercase block">
                  CAPACIDAD ESTÁNDAR
                </span>
                <span className="text-xs font-mono font-bold text-[#F5B800]">
                  {step.metric}
                </span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
