"use client";

import React, { useState } from "react";
import { ArrowUpRight, Check, Filter, Layers, Truck, ShieldCheck, Cpu } from "lucide-react";
import { FLEET_CATALOG, EquipmentItem } from "@/data/fleet";

interface RentalSectionProps {
  onQuoteClick: (machineName?: string) => void;
}

export function RentalSection({ onQuoteClick }: RentalSectionProps) {
  const [selectedCategory, setSelectedCategory] = useState<string>("TODOS");

  const categories = [
    { label: "TODOS", value: "TODOS" },
    { label: "HINCADORA HWL600R", value: "hincadora" },
    { label: "BOBCAT", value: "bobcat" },
  ];

  const filteredFleet = selectedCategory === "TODOS"
    ? FLEET_CATALOG
    : FLEET_CATALOG.filter((item) => item.category === selectedCategory);

  return (
    <section className="relative w-full bg-[#080A0B] py-28 border-t border-[#252B2F]/60 overflow-hidden">
      <div className="max-w-7xl mx-auto px-6 md:px-12">
        {/* HEADER */}
        <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 mb-12">
          <div className="space-y-3 max-w-2xl">
            <div className="inline-flex items-center gap-2 px-3 py-1 bg-[#15191C] border border-[#F5B800]/30 rounded text-[10px] font-mono tracking-widest text-[#F5B800] uppercase font-bold">
              <Truck className="w-3.5 h-3.5" /> MAQUINARIA EN ALQUILER Y SERVICIOS
            </div>
            <h2 className="font-heading text-5xl sm:text-7xl font-extrabold text-[#F5F6F3] uppercase tracking-tighter">
              NEED EQUIPMENT?
            </h2>
            <p className="text-base sm:text-lg text-[#9BA2A6] font-sans font-light">
              Encuentra la maquinaria ideal para tu obra solar o proyecto de infraestructura. Alquiler flexible por hincado, día, mes o servicio completo.
            </p>
          </div>

          {/* FILTER BUTTONS */}
          <div className="flex flex-wrap gap-2">
            {categories.map((cat) => (
              <button
                key={cat.value}
                onClick={() => setSelectedCategory(cat.value)}
                className={`px-4 py-2 text-xs font-mono tracking-wider uppercase font-bold rounded transition-all duration-300 border ${
                  selectedCategory === cat.value
                    ? "bg-[#F5B800] text-[#080A0B] border-[#F5B800] shadow-md"
                    : "bg-[#15191C] text-[#9BA2A6] border-[#252B2F] hover:border-[#F5B800]/40 hover:text-[#F5F6F3]"
                }`}
              >
                {cat.label}
              </button>
            ))}
          </div>
        </div>

        {/* MARKETPLACE GRID */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          {filteredFleet.map((machine) => (
            <div
              key={machine.id}
              className="bg-[#15191C] border border-[#252B2F] rounded-2xl p-8 flex flex-col justify-between hover:border-[#F5B800]/60 transition-all duration-300 group hover:-translate-y-1 shadow-xl"
            >
              <div className="space-y-6">
                {/* CARD HEADER */}
                <div className="flex items-center justify-between border-b border-[#252B2F] pb-4">
                  <span className="text-[10px] font-mono tracking-widest text-[#F5B800] uppercase font-bold">
                    {machine.categoryLabel}
                  </span>
                  <span className="text-[10px] font-mono text-[#9BA2A6] uppercase bg-[#080A0B] px-2 py-1 rounded border border-[#252B2F]">
                    {machine.code}
                  </span>
                </div>

                {/* GRAPHIC CARD BANNER */}
                <div className="h-44 bg-[#080A0B] border border-[#252B2F] rounded-xl flex items-center justify-center relative overflow-hidden group-hover:border-[#F5B800]/40 transition-colors">
                  <div className="text-center space-y-2">
                    <Cpu className="w-10 h-10 text-[#F5B800] mx-auto opacity-80 group-hover:scale-110 transition-transform duration-300" />
                    <span className="text-xs font-mono text-[#F5F6F3] font-bold uppercase block">
                      {machine.operatingWeight} | {machine.enginePower}
                    </span>
                  </div>
                </div>

                {/* TITLE & DESCRIPTION */}
                <div>
                  <h3 className="font-heading text-2xl font-bold text-[#F5F6F3] uppercase tracking-tight group-hover:text-[#F5B800] transition-colors">
                    {machine.name}
                  </h3>
                  <p className="text-xs text-[#9BA2A6] mt-2 font-sans leading-relaxed">
                    {machine.tagline}
                  </p>
                </div>

                {/* QUICK SPECS LIST */}
                <div className="space-y-2 pt-2 border-t border-[#252B2F]">
                  {machine.detailedSpecs.slice(0, 4).map((spec, i) => (
                    <div key={i} className="flex items-center justify-between text-xs">
                      <span className="text-[#9BA2A6] font-mono">{spec.label}:</span>
                      <span className="text-[#F5F6F3] font-mono font-bold">{spec.value}</span>
                    </div>
                  ))}
                </div>
              </div>

              {/* ACTION BUTTON */}
              <div className="pt-6 mt-6 border-t border-[#252B2F]">
                <button
                  onClick={() => onQuoteClick(machine.name)}
                  className="w-full inline-flex items-center justify-center gap-2 py-3.5 bg-[#252B2F] hover:bg-[#F5B800] text-[#F5F6F3] hover:text-[#080A0B] font-mono font-bold text-xs uppercase tracking-widest rounded transition-all duration-300"
                >
                  <span>SOLICITAR COTIZACIÓN DE {machine.code}</span>
                  <ArrowUpRight className="w-4 h-4" />
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
