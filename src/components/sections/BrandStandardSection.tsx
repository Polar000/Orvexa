"use client";

import React from "react";
import { Shield, Zap, Target, Layers } from "lucide-react";
import { BRAND_STANDARDS } from "@/data/projects";

export function BrandStandardSection() {
  return (
    <section id="nosotros" className="relative w-full bg-[#080A0B] py-28 border-t border-[#252B2F]/60 overflow-hidden">
      <div className="max-w-7xl mx-auto px-6 md:px-12">
        {/* HEADER */}
        <div className="space-y-4 mb-16 text-center max-w-3xl mx-auto">
          <div className="inline-flex items-center gap-2 px-3 py-1 bg-[#15191C] border border-[#F5B800]/30 rounded text-[10px] font-mono tracking-widest text-[#F5B800] uppercase font-bold">
            <Shield className="w-3.5 h-3.5" /> THE ORVEXA STANDARD
          </div>
          <h2 className="font-heading text-5xl sm:text-7xl lg:text-8xl font-extrabold text-[#F5F6F3] uppercase tracking-tighter">
            BUILT DIFFERENT.
          </h2>
          <p className="text-base sm:text-lg text-[#9BA2A6] font-sans font-light">
            Cuatro pilares de ingeniería y potencia operativa que respaldan cada contrato.
          </p>
        </div>

        {/* 4 CARDS MINIMALIST TYPOGRAPHIC GRID */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
          {BRAND_STANDARDS.map((item) => (
            <div
              key={item.code}
              className="bg-[#15191C]/80 border border-[#252B2F] rounded-2xl p-8 flex flex-col justify-between hover:border-[#F5B800] transition-all duration-300 group hover:-translate-y-1 shadow-2xl relative overflow-hidden"
            >
              <div className="space-y-6">
                <span className="font-mono text-xs font-bold text-[#F5B800] tracking-widest uppercase block">
                  STANDARD / {item.code}
                </span>

                <h3 className="font-heading text-4xl font-extrabold text-[#F5F6F3] uppercase tracking-tight group-hover:text-[#F5B800] transition-colors">
                  {item.title}
                </h3>

                <p className="text-sm font-mono text-[#F5B800] uppercase font-semibold">
                  {item.sub}
                </p>

                <p className="text-xs text-[#9BA2A6] font-sans leading-relaxed">
                  {item.desc}
                </p>
              </div>

              <div className="pt-8 mt-8 border-t border-[#252B2F] flex items-center justify-between">
                <span className="text-[10px] font-mono text-[#9BA2A6] uppercase">
                  ORVEXA CERTIFIED
                </span>
                <div className="w-2 h-2 rounded-full bg-[#F5B800]" />
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
