"use client";

import React, { useState } from "react";
import { ArrowUpRight, CheckCircle2, ChevronRight, HardHat, ShieldCheck } from "lucide-react";
import { SERVICES, ServiceItem } from "@/data/services";

interface ServicesProps {
  onQuoteClick: () => void;
}

export function ServicesSection({ onQuoteClick }: ServicesProps) {
  const [expandedId, setExpandedId] = useState<string>(SERVICES[0].id);

  return (
    <section id="servicios" className="relative w-full bg-[#15191C] py-28 border-t border-[#252B2F]/60 overflow-hidden">
      <div className="max-w-7xl mx-auto px-6 md:px-12">
        {/* HEADER */}
        <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 mb-16">
          <div className="space-y-3 max-w-2xl">
            <div className="inline-flex items-center gap-2 px-3 py-1 bg-[#252B2F] border border-[#F5B800]/30 rounded text-[10px] font-mono tracking-widest text-[#F5B800] uppercase font-bold">
              <HardHat className="w-3.5 h-3.5" /> WHAT WE DO / CORE CAPABILITIES
            </div>
            <h2 className="font-heading text-5xl sm:text-7xl font-extrabold text-[#F5F6F3] uppercase tracking-tighter">
              WHAT WE DO
            </h2>
            <p className="text-base sm:text-lg text-[#9BA2A6] font-sans font-light">
              Seis divisiones especializadas en maquinaria, movimiento de tierras, perforación y proyectos de energía solar.
            </p>
          </div>
        </div>

        {/* 6 EXPANDABLE CARDS GRID */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {SERVICES.map((service) => {
            const isExpanded = expandedId === service.id;
            return (
              <div
                key={service.id}
                onMouseEnter={() => setExpandedId(service.id)}
                className={`glass-panel rounded-2xl p-8 flex flex-col justify-between transition-all duration-500 cursor-pointer relative overflow-hidden group ${
                  isExpanded
                    ? "border-[#F5B800] bg-[#252B2F]/90 shadow-2xl -translate-y-1"
                    : "border-[#252B2F] bg-[#080A0B]/60 hover:border-[#F5B800]/40"
                }`}
              >
                {/* Yellow Top Border Accent on Active */}
                <div
                  className={`absolute top-0 left-0 right-0 h-1 bg-[#F5B800] transition-opacity duration-300 ${
                    isExpanded ? "opacity-100" : "opacity-0"
                  }`}
                />

                <div className="space-y-6">
                  {/* CARD CODE BADGE & TITLE */}
                  <div className="flex items-center justify-between border-b border-[#252B2F] pb-4">
                    <span className="font-mono text-xl font-black text-[#F5B800]">
                      {service.code}
                    </span>
                    <span className="text-[10px] font-mono tracking-widest text-[#9BA2A6] uppercase">
                      DIVISION / ORVEXA
                    </span>
                  </div>

                  <div>
                    <h3 className="font-heading text-2xl font-extrabold text-[#F5F6F3] uppercase tracking-tight group-hover:text-[#F5B800] transition-colors duration-300">
                      {service.title}
                    </h3>
                    <p className="text-xs font-mono text-[#9BA2A6] mt-1 font-semibold uppercase">
                      {service.subtitle}
                    </p>
                  </div>

                  <p className="text-sm text-[#9BA2A6] font-sans leading-relaxed">
                    {service.shortDesc}
                  </p>

                  {/* EXPANDED CONTENT ON HOVER/ACTIVE */}
                  {isExpanded && (
                    <div className="space-y-4 pt-4 border-t border-[#252B2F]/60 animate-fadeIn">
                      <p className="text-xs text-[#F5F6F3]/90 leading-relaxed font-sans">
                        {service.fullDesc}
                      </p>

                      <div className="space-y-2">
                        {service.features.map((feat, idx) => (
                          <div key={idx} className="flex items-center gap-2 text-xs text-[#9BA2A6]">
                            <CheckCircle2 className="w-3.5 h-3.5 text-[#F5B800] shrink-0" />
                            <span>{feat}</span>
                          </div>
                        ))}
                      </div>

                      {/* KEY METRICS */}
                      <div className="grid grid-cols-2 gap-2 pt-2">
                        {service.metrics.map((m, idx) => (
                          <div key={idx} className="bg-[#080A0B]/80 p-2.5 rounded border border-[#252B2F]">
                            <span className="text-[9px] font-mono text-[#9BA2A6] block uppercase">
                              {m.label}
                            </span>
                            <span className="text-xs font-mono font-bold text-[#F5B800]">
                              {m.value}
                            </span>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </div>

                {/* ACTION BUTTON */}
                <div className="pt-6 mt-6 border-t border-[#252B2F]/60 flex items-center justify-between">
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      onQuoteClick();
                    }}
                    className="inline-flex items-center gap-2 text-xs font-mono font-bold text-[#F5B800] hover:text-[#FFD23F] uppercase tracking-wider group-hover:translate-x-1 transition-all duration-300"
                  >
                    <span>COTIZAR SERVICIO</span>
                    <ArrowUpRight className="w-4 h-4" />
                  </button>
                  <ChevronRight className={`w-5 h-5 text-[#9BA2A6] transition-transform duration-300 ${isExpanded ? "rotate-90 text-[#F5B800]" : ""}`} />
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
