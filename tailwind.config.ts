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
          "dark-gray": "#252B2F",
          white: "#F5F6F3",
          "light-gray": "#9BA2A6",
          "industrial-yellow": "#F5B800",
          "bright-yellow": "#FFD23F",
        },
      },
    },
  },
  plugins: [],
} satisfies Config;
