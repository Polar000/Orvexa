"use client";

import React from "react";
import { ArrowUpRight, Cpu, Gauge, Layers, ShieldCheck, Zap } from "lucide-react";
import { EquipmentItem } from "@/data/fleet";

interface ShowcaseProps {
  selectedMachine: EquipmentItem;
  onQuoteClick: () => void;
}

export function MachineShowcaseSection({ selectedMachine, onQuoteClick }: ShowcaseProps) {
  return (
    <section className="relative w-full bg-[#080A0B] py-20 border-t border-[#252B2F]/60 overflow-hidden">
      <div className="max-w-7xl mx-auto px-6 md:px-12">
        <div className="bg-[#15191C]/90 border border-[#252B2F] rounded-3xl p-8 lg:p-12 relative overflow-hidden shadow-2xl">
          {/* Subtle Industrial Accent Line */}
          <div className="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-transparent via-[#F5B800] to-transparent" />

          <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
            {/* LEFT CONTENT SPECIFICATION DETAILS */}
            <div className="lg:col-span-7 space-y-8">
              <div className="space-y-2">
                <span className="text-xs font-mono tracking-widest text-[#F5B800] uppercase font-bold">
                  {selectedMachine.powerRating} / SHOWCASE
                </span>
                <h3 className="font-heading text-4xl sm:text-6xl font-extrabold text-[#F5F6F3] uppercase tracking-tighter">
                  {selectedMachine.name}
                </h3>
                <p className="text-base text-[#9BA2A6] font-sans font-light">
                  {selectedMachine.tagline}
                </p>
              </div>

              {/* HIGHLIGHT METRICS */}
              <div className="grid grid-cols-3 gap-4 border-y border-[#252B2F] py-6">
                <div>
                  <span className="text-[10px] font-mono text-[#9BA2A6] uppercase block">
                    PESO OPERATIVO
                  </span>
                  <span className="text-2xl font-mono font-bold text-[#F5F6F3]">
                    {selectedMachine.operatingWeight}
                  </span>
                </div>
                <div>
                  <span className="text-[10px] font-mono text-[#9BA2A6] uppercase block">
                    POTENCIA MOTOR
                  </span>
                  <span className="text-2xl font-mono font-bold text-[#F5B800]">
                    {selectedMachine.enginePower}
                  </span>
                </div>
                <div>
                  <span className="text-[10px] font-mono text-[#9BA2A6] uppercase block">
                    CAPACIDAD / MÁX
                  </span>
                  <span className="text-2xl font-mono font-bold text-[#F5F6F3]">
                    {selectedMachine.bucketCapacity || selectedMachine.maxDrillDepth || "100% HD"}
                  </span>
                </div>
              </div>

              {/* DETAILED FEATURES LIST */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="flex items-start gap-3 p-3 bg-[#080A0B]/60 rounded border border-[#252B2F]">
                  <Gauge className="w-5 h-5 text-[#F5B800] shrink-0 mt-0.5" />
                  <div>
                    <span className="text-xs font-mono font-bold text-[#F5F6F3] block">
                      TELEMETRÍA CANBUS
                    </span>
                    <span className="text-[11px] text-[#9BA2A6]">
                      Monitoreo de horas de trabajo y hábitos de operación en tiempo real.
                    </span>
                  </div>
                </div>

                <div className="flex items-start gap-3 p-3 bg-[#080A0B]/60 rounded border border-[#252B2F]">
                  <ShieldCheck className="w-5 h-5 text-[#F5B800] shrink-0 mt-0.5" />
                  <div>
                    <span className="text-xs font-mono font-bold text-[#F5F6F3] block">
                      CERTIFICADO ROPS/FOPS
                    </span>
                    <span className="text-[11px] text-[#9BA2A6]">
                      Cabinas de máxima seguridad y visibilidad panorámica ergonómica.
                    </span>
                  </div>
                </div>
              </div>

              {/* ACTION CALL */}
              <div className="flex items-center gap-4 pt-2">
                <button
                  onClick={onQuoteClick}
                  className="inline-flex items-center gap-2 px-8 py-4 bg-[#F5B800] hover:bg-[#FFD23F] text-[#080A0B] font-mono font-bold text-xs uppercase tracking-widest rounded transition-all duration-300 shadow-xl"
                >
                  <span>CONSULTAR DISPONIBILIDAD Y FLETE</span>
                  <ArrowUpRight className="w-4 h-4" />
                </button>
              </div>
            </div>

            {/* RIGHT GRAPHIC CARD / REAL IMAGE SHOWCASE */}
            <div className="lg:col-span-5 relative flex flex-col items-center justify-center p-6 bg-[#080A0B] border border-[#252B2F] rounded-2xl min-h-[360px] overflow-hidden group">
              <div className="absolute inset-0 bg-radial-gradient from-[#F5B800]/10 via-transparent to-transparent pointer-events-none" />

              {selectedMachine.image ? (
                <div className="relative w-full h-full flex flex-col items-center justify-center space-y-4">
                  <div className="relative w-full h-64 flex items-center justify-center">
                    <img
                      src={selectedMachine.image}
                      alt={selectedMachine.name}
                      className="max-h-full max-w-full object-contain drop-shadow-[0_10px_20px_rgba(245,184,0,0.15)] group-hover:scale-105 transition-transform duration-500"
                    />
                  </div>
                  <div className="text-center space-y-1">
                    <span className="text-xs font-mono text-[#F5B800] font-bold tracking-widest uppercase block">
                      FOTOGRAFÍA REAL / EQUIPO OFICIAL
                    </span>
                    <p className="text-xs text-[#9BA2A6]">
                      {selectedMachine.name} en configuración operativa de alto rendimiento.
                    </p>
                  </div>
                </div>
              ) : (
                <div className="text-center space-y-4">
                  <div className="w-16 h-16 mx-auto bg-[#15191C] border border-[#F5B800]/40 rounded-full flex items-center justify-center yellow-glow">
                    <Cpu className="w-8 h-8 text-[#F5B800]" />
                  </div>
                  <div className="space-y-1">
                    <span className="text-xs font-mono text-[#F5B800] font-bold tracking-widest uppercase block">
                      SPECS ARCHITECTURE
                    </span>
                    <p className="text-sm text-[#F5F6F3] font-bold">
                      {selectedMachine.code} HEAVY DUTY
                    </p>
                    <span className="text-xs text-[#9BA2A6] block max-w-xs mx-auto">
                      Preparada para despliegue inmediato en obras de infraestructura civil, minería y energía.
                    </span>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
