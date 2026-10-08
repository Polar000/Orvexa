"use client";

import React, { Component, ReactNode } from "react";
import { AlertTriangle, RefreshCw } from "lucide-react";

interface Props {
  children: ReactNode;
  fallbackText?: string;
}

interface State {
  hasError: boolean;
  error?: Error;
}

export class WebGLErrorBoundary extends Component<Props, State> {
  public state: State = {
    hasError: false,
  };

  public static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  public componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error("WebGL 3D Engine Error:", error, errorInfo);
  }

  public render() {
    if (this.state.hasError) {
      return (
        <div className="w-full h-full min-h-[300px] flex flex-col items-center justify-center bg-[#15191C]/80 border border-[#252B2F] p-8 text-center rounded-xl backdrop-blur-md">
          <AlertTriangle className="w-12 h-12 text-[#F5B800] mb-4 animate-pulse" />
          <h3 className="text-xl font-heading font-bold text-[#F5F6F3] mb-2 uppercase tracking-wider">
            {this.props.fallbackText || "Vista 3D Interactiva No Disponible"}
          </h3>
          <p className="text-sm text-[#9BA2A6] max-w-md mb-6">
            Tu navegador o aceleración gráfica actual está operando en modo simplificado. Puedes continuar explorando todas las especificaciones de ORVEXA.
          </p>
          <button
            onClick={() => this.setState({ hasError: false })}
            className="inline-flex items-center gap-2 px-5 py-2.5 bg-[#252B2F] hover:bg-[#F5B800] text-[#F5F6F3] hover:text-[#080A0B] text-xs font-mono tracking-widest font-bold uppercase transition-all duration-300 rounded"
          >
            <RefreshCw className="w-4 h-4" /> RECARGAR ESCENA 3D
          </button>
        </div>
      );
    }

    return this.props.children;
  }
}
