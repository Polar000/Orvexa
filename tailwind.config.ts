import type { Config } from "tailwindcss";

export default {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        orvexa: {
          black: "#080A0B",
          graphite: "#15191C",
          darkGray: "#252B2F",
          white: "#F5F6F3",
          lightGray: "#9BA2A6",
          yellow: "#F5B800",
          brightYellow: "#FFD23F",
        },
      },
      fontFamily: {
        heading: ["Space Grotesk", "sans-serif"],
        body: ["Inter", "sans-serif"],
      },
    },
  },
  plugins: [],
} satisfies Config;
