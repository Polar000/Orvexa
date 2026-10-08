"use client";

import React, { useState } from "react";
import { Canvas } from "@react-three/fiber";
import { ArrowRight, CheckCircle2, Mail, MapPin, Phone, Send, ShieldCheck } from "lucide-react";
import { Fleet3DMachinery } from "@/components/3d/Fleet3DMachinery";
import { IndustrialTerrain } from "@/components/3d/IndustrialTerrain";
import { WebGLErrorBoundary } from "@/components/3d/WebGLErrorBoundary";

interface ContactProps {
  initialMachine?: string;
  isOpenModal?: boolean;
  onCloseModal?: () => void;
}

export function ContactSection({ initialMachine, isOpenModal, onCloseModal }: ContactProps) {
  const [submitted, setSubmitted] = useState(false);
  const [formData, setFormData] = useState({
    name: "",
    company: "",
    phone: "",
    email: "",
    location: "",
    projectType: "Movimiento de Tierras",
    machinery: initialMachine || "Excavadora EX-350 HD",
    message: "",
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitted(true);
  };

  return (
    <section id="contacto" className="relative w-full bg-[#080A0B] py-28 border-t border-[#252B2F]/60 overflow-hidden">
      <div className="max-w-7xl mx-auto px-6 md:px-12">
        {/* SPECTACULAR 3D BACKGROUND CLOSING HERO */}
        <div className="relative bg-[#15191C] border border-[#252B2F] rounded-3xl p-8 lg:p-12 mb-16 overflow-hidden shadow-2xl">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-center">
            {/* TEXT LEFT */}
            <div className="lg:col-span-6 space-y-6 z-10">
              <div className="inline-flex items-center gap-2 px-3 py-1 bg-[#080A0B] border border-[#F5B800]/30 rounded text-[10px] font-mono tracking-widest text-[#F5B800] uppercase font-bold">
                ORVEXA / CONTACT & QUOTATION
              </div>
              <h2 className="font-heading text-5xl sm:text-7xl font-extrabold text-[#F5F6F3] uppercase tracking-tighter leading-none">
                HAVE A PROJECT <br />
                <span className="text-[#F5B800]">IN MIND?</span>
              </h2>
              <p className="text-base sm:text-lg text-[#9BA2A6] font-sans font-light max-w-lg">
                Pongamos la maquinaria a trabajar. Solicita una cotización técnica o consulta la disponibilidad de flota en tiempo real.
              </p>
              <div className="flex flex-wrap gap-4 pt-2">
                <a
                  href="#contact-form"
                  className="inline-flex items-center gap-2 px-8 py-4 bg-[#F5B800] hover:bg-[#FFD23F] text-[#080A0B] font-mono font-bold text-xs uppercase tracking-widest rounded transition-all duration-300 shadow-xl"
                >
                  <span>SOLICITAR COTIZACIÓN</span>
                  <ArrowRight className="w-4 h-4" />
                </a>
              </div>
            </div>

            {/* DRAMATIC DARK 3D MACHINE VIEWPORT */}
            <div className="lg:col-span-6 relative h-[320px] bg-[#080A0B] border border-[#252B2F] rounded-2xl overflow-hidden">
              <WebGLErrorBoundary>
                <Canvas
                  shadows
                  camera={{ position: [0, 2, 5.5], fov: 45 }}
                  gl={{ antialias: true, alpha: false }}
                >
                  <color attach="background" args={["#080A0B"]} />
                  <fog attach="fog" args={["#080A0B", 4, 14]} />

                  <ambientLight intensity={0.2} />
                  {/* Dramatic Yellow Industrial Spotlight in the Dark */}
                  <spotLight
                    position={[3, 5, 4]}
                    intensity={6.0}
                    color="#F5B800"
                    angle={0.6}
                    penumbra={0.9}
                    castShadow
                  />
                  <pointLight position={[-3, 2, -2]} intensity={1.5} color="#FFD23F" />

                  <Fleet3DMachinery type="excavator" colorAccent="#F5B800" />
                  <IndustrialTerrain />
                </Canvas>
              </WebGLErrorBoundary>

              <div className="absolute bottom-3 left-3 bg-[#15191C]/80 px-3 py-1 rounded text-[10px] font-mono text-[#F5B800] border border-[#252B2F]">
                ORVEXA POWER SPOTLIGHT
              </div>
            </div>
          </div>
        </div>

        {/* INDUSTRIAL PANEL FORM & DIRECT CONTACT INFO */}
        <div id="contact-form" className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-start">
          {/* DIRECT CONTACT DETAILS */}
          <div className="lg:col-span-5 space-y-8">
            <div className="space-y-3">
              <span className="text-xs font-mono tracking-widest text-[#F5B800] uppercase font-bold">
                DIRECT CHANNELS
              </span>
              <h3 className="font-heading text-3xl font-extrabold text-[#F5F6F3] uppercase tracking-tight">
                HABLAR CON ORVEXA
              </h3>
              <p className="text-sm text-[#9BA2A6] font-sans">
                Atención técnica comercial para licitaciones, alquileres e ingeniería de campo.
              </p>
            </div>

            <div className="space-y-4">
              <div className="flex items-center gap-4 p-4 bg-[#15191C] border border-[#252B2F] rounded-xl">
                <Phone className="w-6 h-6 text-[#F5B800]" />
                <div>
                  <span className="text-[10px] font-mono text-[#9BA2A6] uppercase block">
                    TELÉFONO DE ATENCIÓN
                  </span>
                  <span className="text-sm font-mono font-bold text-[#F5F6F3]">
                    +52 800 ORVEXA / +52 (55) 8920-3000
                  </span>
                </div>
              </div>

              <div className="flex items-center gap-4 p-4 bg-[#15191C] border border-[#252B2F] rounded-xl">
                <Mail className="w-6 h-6 text-[#F5B800]" />
                <div>
                  <span className="text-[10px] font-mono text-[#9BA2A6] uppercase block">
                    CORREO ELECTRÓNICO
                  </span>
                  <span className="text-sm font-mono font-bold text-[#F5F6F3]">
                    contacto@orvexa.com
                  </span>
                </div>
              </div>

              <div className="flex items-center gap-4 p-4 bg-[#15191C] border border-[#252B2F] rounded-xl">
                <MapPin className="w-6 h-6 text-[#F5B800]" />
                <div>
                  <span className="text-[10px] font-mono text-[#9BA2A6] uppercase block">
                    OFICINAS CENTRALES Y PATIO
                  </span>
                  <span className="text-xs font-sans text-[#F5F6F3]">
                    Parque Industrial Infraestructura Central, Av. de la Maquinaria 450, Módulo A.
                  </span>
                </div>
              </div>
            </div>
          </div>

          {/* FORM PANEL */}
          <div className="lg:col-span-7 bg-[#15191C] border border-[#252B2F] rounded-3xl p-8 lg:p-10 shadow-2xl">
            {submitted ? (
              <div className="py-12 text-center space-y-4">
                <div className="w-16 h-16 bg-[#F5B800]/20 border border-[#F5B800] text-[#F5B800] rounded-full flex items-center justify-center mx-auto yellow-glow">
                  <CheckCircle2 className="w-8 h-8" />
                </div>
                <h4 className="font-heading text-2xl font-extrabold text-[#F5F6F3] uppercase tracking-tight">
                  SOLICITUD ENVIADA CON ÉXITO
                </h4>
                <p className="text-sm text-[#9BA2A6] max-w-md mx-auto">
                  Un ingeniero especialista de ORVEXA revisará las especificaciones de tu proyecto y se comunicará en menos de 2 horas.
                </p>
                <button
                  onClick={() => setSubmitted(false)}
                  className="px-6 py-2.5 bg-[#252B2F] text-[#F5F6F3] text-xs font-mono font-bold uppercase tracking-wider rounded hover:bg-[#F5B800] hover:text-[#080A0B] transition-colors"
                >
                  ENVIAR OTRA CONSULTA
                </button>
              </div>
            ) : (
              <form onSubmit={handleSubmit} className="space-y-6">
                <div className="border-b border-[#252B2F] pb-4 flex items-center justify-between">
                  <span className="text-xs font-mono font-bold text-[#F5B800] uppercase tracking-widest">
                    PANEL DE COTIZACIÓN TÉCNICA
                  </span>
                  <span className="text-[10px] font-mono text-[#9BA2A6] uppercase">
                    FORMULARIO OFICIAL
                  </span>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <label className="text-[11px] font-mono text-[#9BA2A6] uppercase block mb-1">
                      NOMBRE Y APELLIDO *
                    </label>
                    <input
                      type="text"
                      required
                      placeholder="Ing. Carlos Mendoza"
                      value={formData.name}
                      onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                      className="w-full bg-[#080A0B] border border-[#252B2F] focus:border-[#F5B800] rounded px-4 py-3 text-xs text-[#F5F6F3] outline-none font-mono"
                    />
                  </div>

                  <div>
                    <label className="text-[11px] font-mono text-[#9BA2A6] uppercase block mb-1">
                      EMPRESA / CONSTRUCTORA *
                    </label>
                    <input
                      type="text"
                      required
                      placeholder="Infraestructura Global S.A."
                      value={formData.company}
                      onChange={(e) => setFormData({ ...formData, company: e.target.value })}
                      className="w-full bg-[#080A0B] border border-[#252B2F] focus:border-[#F5B800] rounded px-4 py-3 text-xs text-[#F5F6F3] outline-none font-mono"
                    />
                  </div>

                  <div>
                    <label className="text-[11px] font-mono text-[#9BA2A6] uppercase block mb-1">
                      TELÉFONO DE CONTACTO *
                    </label>
                    <input
                      type="tel"
                      required
                      placeholder="+52 55 1234 5678"
                      value={formData.phone}
                      onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                      className="w-full bg-[#080A0B] border border-[#252B2F] focus:border-[#F5B800] rounded px-4 py-3 text-xs text-[#F5F6F3] outline-none font-mono"
                    />
                  </div>

                  <div>
                    <label className="text-[11px] font-mono text-[#9BA2A6] uppercase block mb-1">
                      CORREO ELECTRÓNICO *
                    </label>
                    <input
                      type="email"
                      required
                      placeholder="carlos@empresa.com"
                      value={formData.email}
                      onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                      className="w-full bg-[#080A0B] border border-[#252B2F] focus:border-[#F5B800] rounded px-4 py-3 text-xs text-[#F5F6F3] outline-none font-mono"
                    />
                  </div>

                  <div>
                    <label className="text-[11px] font-mono text-[#9BA2A6] uppercase block mb-1">
                      UBICACIÓN DEL PROYECTO
                    </label>
                    <input
                      type="text"
                      placeholder="Ciudad, Estado o Región"
                      value={formData.location}
                      onChange={(e) => setFormData({ ...formData, location: e.target.value })}
                      className="w-full bg-[#080A0B] border border-[#252B2F] focus:border-[#F5B800] rounded px-4 py-3 text-xs text-[#F5F6F3] outline-none font-mono"
                    />
                  </div>

                  <div>
                    <label className="text-[11px] font-mono text-[#9BA2A6] uppercase block mb-1">
                      TIPO DE PROYECTO
                    </label>
                    <select
                      value={formData.projectType}
                      onChange={(e) => setFormData({ ...formData, projectType: e.target.value })}
                      className="w-full bg-[#080A0B] border border-[#252B2F] focus:border-[#F5B800] rounded px-4 py-3 text-xs text-[#F5F6F3] outline-none font-mono"
                    >
                      <option value="Movimiento de Tierras">Movimiento de Tierras</option>
                      <option value="Alquiler de Maquinaria">Alquiler de Maquinaria</option>
                      <option value="Perforación Geotécnica">Perforación Geotécnica</option>
                      <option value="Infraestructura Solar">Infraestructura Solar</option>
                      <option value="Obra Civil General">Obra Civil General</option>
                    </select>
                  </div>
                </div>

                <div>
                  <label className="text-[11px] font-mono text-[#9BA2A6] uppercase block mb-1">
                    MAQUINARIA / SERVICIO REQUERIDO
                  </label>
                  <input
                    type="text"
                    value={formData.machinery}
                    onChange={(e) => setFormData({ ...formData, machinery: e.target.value })}
                    className="w-full bg-[#080A0B] border border-[#252B2F] focus:border-[#F5B800] rounded px-4 py-3 text-xs text-[#F5F6F3] outline-none font-mono"
                  />
                </div>

                <div>
                  <label className="text-[11px] font-mono text-[#9BA2A6] uppercase block mb-1">
                    DETALLES DEL MENSAJE / ESPECIFICACIONES
                  </label>
                  <textarea
                    rows={4}
                    placeholder="Describe volúmenes, plazos de ejecución o requerimientos específicos de tu obra..."
                    value={formData.message}
                    onChange={(e) => setFormData({ ...formData, message: e.target.value })}
                    className="w-full bg-[#080A0B] border border-[#252B2F] focus:border-[#F5B800] rounded px-4 py-3 text-xs text-[#F5F6F3] outline-none font-mono resize-none"
                  />
                </div>

                <button
                  type="submit"
                  className="w-full inline-flex items-center justify-center gap-2 py-4 bg-[#F5B800] hover:bg-[#FFD23F] text-[#080A0B] font-mono font-bold text-xs uppercase tracking-widest rounded transition-all duration-300 shadow-xl"
                >
                  <span>ENVIAR SOLICITUD DE COTIZACIÓN</span>
                  <Send className="w-4 h-4" />
                </button>
              </form>
            )}
          </div>
        </div>

        {/* FOOTER CREDITS & FOOTNOTE */}
        <footer className="mt-24 pt-8 border-t border-[#252B2F] flex flex-col md:flex-row items-center justify-between gap-4 text-xs font-mono text-[#9BA2A6]">
          <div className="flex items-center gap-2">
            <span className="font-extrabold text-[#F5F6F3] font-heading text-lg tracking-widest">ORVEXA</span>
            <span>© ORVEXA INFRASTRUCTURE & HEAVY MACHINERY. ALL RIGHTS RESERVED.</span>
          </div>
          <div className="flex gap-6">
            <span>THE POWER BEHIND THE PROJECT.</span>
          </div>
        </footer>
      </div>
    </section>
  );
}
