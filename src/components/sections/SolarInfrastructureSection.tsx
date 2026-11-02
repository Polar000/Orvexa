"use client";

import React from "react";
import { Canvas } from "@react-three/fiber";
import { ArrowRight, CheckCircle2, Sun, Zap } from "lucide-react";
import { Fleet3DMachinery } from "@/components/3d/Fleet3DMachinery";
import { IndustrialTerrain } from "@/components/3d/IndustrialTerrain";
import { WebGLErrorBoundary } from "@/components/3d/WebGLErrorBoundary";

interface SolarProps {
  onQuoteClick: () => void;
}

export function SolarInfrastructureSection({ onQuoteClick }: SolarProps) {
  return (
    <section className="relative w-full bg-[#15191C] py-28 border-t border-[#252B2F]/60 overflow-hidden">
      <div className="max-w-7xl mx-auto px-6 md:px-12">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
          {/* TEXTUAL CONTENT */}
          <div className="lg:col-span-6 space-y-8">
            <div className="space-y-3">
              <div className="inline-flex items-center gap-2 px-3 py-1 bg-[#252B2F] border border-[#F5B800]/30 rounded text-[10px] font-mono tracking-widest text-[#F5B800] uppercase font-bold">
                <Sun className="w-3.5 h-3.5" /> DIVISION DE INFRAESTRUCTURA SOLAR
              </div>
              <h2 className="font-heading text-5xl sm:text-7xl font-extrabold text-[#F5F6F3] uppercase tracking-tighter leading-none">
                BUILDING THE <br />
                <span className="text-transparent bg-clip-text bg-gradient-to-r from-[#F5B800] to-[#FFD23F]">
                  ENERGY
                </span> <br />
                INFRASTRUCTURE.
              </h2>
            </div>

            <p className="text-base sm:text-lg text-[#9BA2A6] font-sans font-light leading-relaxed">
              Maquinaria de alta precisión y capacidad operativa para proyectos de energía fotovoltaica a gran escala. Acondicionamiento de terreno, zanjado automatizado e hincado centimetral.
            </p>

            <div className="space-y-3">
              {[
                "Hincado de perfiles con precisión GPS RTK centimetral (< 10mm)",
                "Rendimiento comprobado de hasta 450 postes hincados por jornada",
                "Apertura de microzanjas para cableado de media y baja tensión",
                "Nivelación y compactación de vialidades internas de parque solar",
              ].map((item, idx) => (
                <div key={idx} className="flex items-start gap-3">
                  <CheckCircle2 className="w-5 h-5 text-[#F5B800] shrink-0 mt-0.5" />
                  <span className="text-sm text-[#F5F6F3] font-sans">{item}</span>
                </div>
              ))}
            </div>

            <div className="pt-4">
              <button
                onClick={onQuoteClick}
                className="inline-flex items-center gap-3 px-8 py-4 bg-[#F5B800] hover:bg-[#FFD23F] text-[#080A0B] font-mono font-bold text-xs uppercase tracking-widest rounded transition-all duration-300 shadow-xl"
              >
                <span>CONOCER SOLUCIONES SOLARES</span>
                <ArrowRight className="w-4 h-4" />
              </button>
            </div>
          </div>

          {/* 3D SOLAR FIELD CANVAS */}
          <div className="lg:col-span-6 relative bg-[#080A0B] border border-[#252B2F] rounded-3xl min-h-[460px] overflow-hidden shadow-2xl">
            <WebGLErrorBoundary>
              <Canvas
                shadows
                camera={{ position: [0, 2, 6], fov: 45 }}
                gl={{ antialias: true, alpha: false }}
              >
                <color attach="background" args={["#080A0B"]} />
                <fog attach="fog" args={["#080A0B", 5, 16]} />

                <ambientLight intensity={0.5} />
                <directionalLight position={[8, 10, 5]} intensity={2.2} castShadow />
                <spotLight position={[-4, 6, -2]} intensity={3.5} color="#F5B800" angle={0.5} />

                {/* Solar Rig + Solar Panel Terrain Props */}
                <Fleet3DMachinery type="solar_rig" colorAccent="#F5B800" />
                <IndustrialTerrain showSolarPanels={true} />
              </Canvas>
            </WebGLErrorBoundary>

            <div className="absolute bottom-4 left-4 right-4 bg-[#15191C]/90 border border-[#252B2F] p-4 rounded-xl backdrop-blur-md flex items-center justify-between">
              <div>
                <span className="text-xs font-mono font-bold text-[#F5F6F3] uppercase block">
                  HINCADORA AUTOMATIZADA SL-500
                </span>
                <span className="text-[10px] font-mono text-[#9BA2A6]">
                  450 POSTES / DÍA | GPS RTK INTEGRADO
                </span>
              </div>
              <Zap className="w-6 h-6 text-[#F5B800]" />
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
