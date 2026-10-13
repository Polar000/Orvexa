"use client";

import React, { useState } from "react";
import { Canvas } from "@react-three/fiber";
import { OrbitControls } from "@react-three/drei";
import { ArrowRight, CheckCircle2, Cpu, Rotate3D, ShieldCheck, Zap } from "lucide-react";
import { FLEET_CATALOG, EquipmentItem } from "@/data/fleet";
import { Fleet3DMachinery } from "@/components/3d/Fleet3DMachinery";
import { IndustrialTerrain } from "@/components/3d/IndustrialTerrain";
import { WebGLErrorBoundary } from "@/components/3d/WebGLErrorBoundary";

interface FleetSectionProps {
  onSelectMachine: (machine: EquipmentItem) => void;
  onQuoteClick: () => void;
}

export function FleetShowroomSection({ onSelectMachine, onQuoteClick }: FleetSectionProps) {
  const [activeMachine, setActiveMachine] = useState<EquipmentItem>(FLEET_CATALOG[0]);

  return (
    <section id="maquinaria" className="relative w-full min-h-screen bg-[#15191C] py-24 border-t border-[#252B2F]/60 overflow-hidden">
      <div className="max-w-7xl mx-auto px-6 md:px-12">
        {/* SECTION HEADER */}
        <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 mb-12">
          <div className="space-y-3">
            <div className="inline-flex items-center gap-2 px-3 py-1 bg-[#252B2F] border border-[#F5B800]/30 rounded text-[10px] font-mono tracking-widest text-[#F5B800] uppercase font-bold">
              <Rotate3D className="w-3.5 h-3.5" /> 3D INTERACTIVE SHOWROOM
            </div>
            <h2 className="font-heading text-5xl sm:text-7xl font-extrabold text-[#F5F6F3] uppercase tracking-tighter">
              THE FLEET
            </h2>
            <p className="text-base sm:text-lg text-[#9BA2A6] max-w-xl font-sans font-light">
              Equipos preparados para trabajos pesados que no pueden detenerse. Selecciona y examina cada unidad en 3D.
            </p>
          </div>

          {/* CATEGORY SWITCHER BUTTONS */}
          <div className="flex flex-wrap gap-2">
            {FLEET_CATALOG.map((item) => (
              <button
                key={item.id}
                onClick={() => {
                  setActiveMachine(item);
                  onSelectMachine(item);
                }}
                className={`px-4 py-2.5 text-xs font-mono tracking-wider uppercase font-bold rounded transition-all duration-300 border ${
                  activeMachine.id === item.id
                    ? "bg-[#F5B800] text-[#080A0B] border-[#F5B800] shadow-lg shadow-[#F5B800]/20"
                    : "bg-[#080A0B]/60 text-[#9BA2A6] border-[#252B2F] hover:border-[#F5B800]/40 hover:text-[#F5F6F3]"
                }`}
              >
                {item.code}
              </button>
            ))}
          </div>
        </div>

        {/* SHOWROOM GRID: 3D VIEWPORT + MACHINE SPECS PANEL */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-stretch">
          {/* 3D CANVAS VIEWPORT */}
          <div className="lg:col-span-7 relative bg-[#080A0B] border border-[#252B2F] rounded-2xl min-h-[420px] lg:min-h-[560px] overflow-hidden group shadow-2xl">
            <WebGLErrorBoundary>
              <Canvas
                shadows
                camera={{ position: [0, 2, 6], fov: 45 }}
                gl={{ antialias: true, alpha: false }}
              >
                <color attach="background" args={["#080A0B"]} />
                <fog attach="fog" args={["#080A0B", 6, 18]} />

                <ambientLight intensity={0.5} />
                <directionalLight position={[6, 10, 5]} intensity={2.0} castShadow />
                <spotLight position={[-4, 6, -2]} intensity={3.5} color="#F5B800" angle={0.5} />

                {/* Dynamic Machinery Model */}
                <Fleet3DMachinery type={activeMachine.model3DType} colorAccent="#F5B800" />
                <IndustrialTerrain />

                <OrbitControls
                  enableZoom={true}
                  minDistance={3.5}
                  maxDistance={10}
                  maxPolarAngle={Math.PI / 2 - 0.05}
                />
              </Canvas>
            </WebGLErrorBoundary>

            {/* Viewport Overlay Controls Hint */}
            <div className="absolute top-4 left-4 flex items-center gap-2 px-3 py-1.5 bg-[#15191C]/80 backdrop-blur-md border border-[#252B2F] rounded text-[10px] font-mono text-[#9BA2A6]">
              <Rotate3D className="w-3.5 h-3.5 text-[#F5B800]" />
              <span>ROTA 360° | ZOOM CON SCROLL</span>
            </div>

            <div className="absolute bottom-4 right-4 flex items-center gap-2 px-3 py-1.5 bg-[#15191C]/80 backdrop-blur-md border border-[#252B2F] rounded text-[10px] font-mono text-[#F5B800] uppercase font-bold">
              <span>{activeMachine.powerRating}</span>
            </div>
          </div>

          {/* ACTIVE MACHINE SPECS OVERLAY PANEL */}
          <div className="lg:col-span-5 bg-[#080A0B]/80 border border-[#252B2F] rounded-2xl p-8 flex flex-col justify-between space-y-8 backdrop-blur-md">
            <div className="space-y-6">
              <div className="flex items-center justify-between border-b border-[#252B2F] pb-4">
                <span className="text-xs font-mono tracking-widest text-[#F5B800] uppercase font-bold">
                  {activeMachine.categoryLabel}
                </span>
                <span
                  className={`text-[10px] font-mono tracking-widest uppercase font-bold px-2.5 py-1 rounded border ${
                    activeMachine.availability === "IMMEDIATE"
                      ? "bg-emerald-500/10 text-emerald-400 border-emerald-500/30"
                      : "bg-amber-500/10 text-amber-400 border-amber-500/30"
                  }`}
                >
                  DISPONIBILIDAD: {activeMachine.availability === "IMMEDIATE" ? "INMEDIATA" : "EN OPERACIÓN"}
                </span>
              </div>

              <div>
                <h3 className="font-heading text-3xl font-extrabold text-[#F5F6F3] uppercase tracking-tight">
                  {activeMachine.name}
                </h3>
                <p className="text-sm text-[#9BA2A6] mt-2 font-sans leading-relaxed">
                  {activeMachine.description}
                </p>
              </div>

              {/* TECHNICAL SPECIFICATIONS GRID */}
              <div className="space-y-3 pt-2">
                <span className="text-xs font-mono text-[#F5F6F3] font-bold uppercase tracking-wider block">
                  ESPECIFICACIONES TÉCNICAS:
                </span>
                <div className="grid grid-cols-2 gap-3">
                  {activeMachine.detailedSpecs.map((spec, i) => (
                    <div
                      key={i}
                      className="bg-[#15191C] border border-[#252B2F] p-3 rounded"
                    >
                      <span className="text-[10px] font-mono text-[#9BA2A6] block uppercase">
                        {spec.label}
                      </span>
                      <span className="text-sm font-mono font-bold text-[#F5B800]">
                        {spec.value}
                      </span>
                    </div>
                  ))}
                </div>
              </div>

              {/* APPLICATIONS LIST */}
              <div className="space-y-2">
                <span className="text-xs font-mono text-[#F5F6F3] font-bold uppercase tracking-wider block">
                  APLICACIONES CLAVE:
                </span>
                <ul className="space-y-1.5">
                  {activeMachine.applications.map((app, i) => (
                    <li key={i} className="flex items-start gap-2 text-xs text-[#9BA2A6]">
                      <CheckCircle2 className="w-3.5 h-3.5 text-[#F5B800] shrink-0 mt-0.5" />
                      <span>{app}</span>
                    </li>
                  ))}
                </ul>
              </div>
            </div>

            {/* ACTION BUTTON */}
            <div className="pt-4 border-t border-[#252B2F] flex flex-col sm:flex-row gap-3">
              <button
                onClick={onQuoteClick}
                className="w-full inline-flex items-center justify-center gap-2 px-6 py-4 bg-[#F5B800] hover:bg-[#FFD23F] text-[#080A0B] font-mono font-bold text-xs uppercase tracking-widest rounded transition-all duration-300 shadow-lg"
              >
                <span>SOLICITAR INFORMACIÓN DE {activeMachine.code}</span>
                <ArrowRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
