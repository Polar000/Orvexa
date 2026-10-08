"use client";

import React, { useRef, useMemo } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";

interface IndustrialTerrainProps {
  showSolarPanels?: boolean;
}

export function IndustrialTerrain({ showSolarPanels = false }: IndustrialTerrainProps) {
  const particlesRef = useRef<THREE.Points>(null);

  // Generate atmospheric floating dust particles
  const particleCount = 250;
  const positions = useMemo(() => {
    const pos = new Float32Array(particleCount * 3);
    for (let i = 0; i < particleCount; i++) {
      pos[i * 3] = (Math.random() - 0.5) * 20;
      pos[i * 3 + 1] = Math.random() * 6;
      pos[i * 3 + 2] = (Math.random() - 0.5) * 20;
    }
    return pos;
  }, [particleCount]);

  useFrame((state) => {
    if (particlesRef.current) {
      const time = state.clock.getElapsedTime();
      const posArray = particlesRef.current.geometry.attributes.position.array as Float32Array;
      for (let i = 0; i < particleCount; i++) {
        // Slow vertical drift & gentle swirl
        posArray[i * 3 + 1] += Math.sin(time + i) * 0.002;
        if (posArray[i * 3 + 1] < 0) posArray[i * 3 + 1] = 6;
        if (posArray[i * 3 + 1] > 6) posArray[i * 3 + 1] = 0;
      }
      particlesRef.current.geometry.attributes.position.needsUpdate = true;
    }
  });

  return (
    <group>
      {/* Dark Industrial Soil Ground */}
      <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, -0.65, 0]} receiveShadow>
        <planeGeometry args={[60, 60]} />
        <meshStandardMaterial
          color="#121517"
          roughness={0.9}
          metalness={0.2}
        />
      </mesh>

      {/* Grid Floor Overlay for High-Tech feel */}
      <gridHelper args={[60, 60, "#F5B800", "#252B2F"]} position={[0, -0.64, 0]} />

      {/* Floating Dust Particles */}
      <points ref={particlesRef}>
        <bufferGeometry>
          <bufferAttribute
            attach="attributes-position"
            args={[positions, 3]}
          />
        </bufferGeometry>
        <pointsMaterial
          size={0.06}
          color="#F5B800"
          transparent
          opacity={0.4}
          sizeAttenuation
        />
      </points>

      {/* Optional Solar Panel Array Ground Props */}
      {showSolarPanels && (
        <group position={[0, -0.6, -6]}>
          {[-6, -2, 2, 6].map((x, colIdx) =>
            [-2, 2].map((z, rowIdx) => (
              <group key={`sol-${colIdx}-${rowIdx}`} position={[x, 0.6, z]} rotation={[0.4, 0, 0]}>
                {/* Structural Support Post */}
                <mesh position={[0, -0.6, 0]}>
                  <cylinderGeometry args={[0.05, 0.05, 1.2, 8]} />
                  <meshStandardMaterial color="#9BA2A6" metalness={0.8} />
                </mesh>
                {/* Photovoltaic Panel */}
                <mesh castShadow receiveShadow>
                  <boxGeometry args={[3.2, 0.04, 1.8]} />
                  <meshStandardMaterial color="#0F172A" roughness={0.1} metalness={0.9} />
                </mesh>
              </group>
            ))
          )}
        </group>
      )}
    </group>
  );
}
