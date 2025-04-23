// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")

module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/startup_game_web.ex",
    "../lib/startup_game_web/**/*.*ex"
  ],
  plugins: [
    require("@tailwindcss/forms"),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({addVariant}) => addVariant("phx-no-feedback", [".phx-no-feedback&", ".phx-no-feedback &"])),
    plugin(({addVariant}) => addVariant("phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])),
    plugin(({addVariant}) => addVariant("phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])),
    plugin(({addVariant}) => addVariant("phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"])),

    // Embeds Heroicons (https://heroicons.com) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function({matchComponents, theme}) {
      let iconsDir = path.join(__dirname, "../deps/heroicons/optimized")
      let values = {}
      let icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"],
        ["-micro", "/16/solid"]
      ]
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).forEach(file => {
          let name = path.basename(file, ".svg") + suffix
          values[name] = {name, fullPath: path.join(iconsDir, dir, file)}
        })
      })
      matchComponents({
        "hero": ({name, fullPath}) => {
          let content = fs.readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "")
          let size = theme("spacing.6")
          if (name.endsWith("-mini")) {
            size = theme("spacing.5")
          } else if (name.endsWith("-micro")) {
            size = theme("spacing.4")
          }
          return {
            [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
            "-webkit-mask": `var(--hero-${name})`,
            "mask": `var(--hero-${name})`,
            "mask-repeat": "no-repeat",
            "background-color": "currentColor",
            "vertical-align": "middle",
            "display": "inline-block",
            "width": size,
            "height": size
          }
        }
      }, {values})
    }),
    plugin(({ addComponents }) => {
      addComponents({
        ".glass-card": {
          "@apply bg-white/80 backdrop-blur-sm border border-white/20 shadow-lg rounded-2xl": {},
        },
        ".glass-card-blur": {
          "@apply bg-white/90 backdrop-blur-md border border-white/20 shadow-lg": {},
        },
        ".silly-button": {
          "@apply px-6 py-3 font-medium rounded-full transition-all duration-300 transform hover:scale-105 focus:outline-none focus:ring-2 focus:ring-offset-2": {},
        },
        ".silly-button-primary": {
          "@apply silly-button bg-silly-blue text-white hover:shadow-lg hover:shadow-silly-blue/20 focus:ring-silly-blue/50": {},
        },
        ".silly-button-secondary": {
          "@apply silly-button bg-white text-silly-gray border border-gray-200 hover:bg-gray-50 hover:shadow-md focus:ring-gray-200": {},
        },
        ".silly-button-accent": {
          "@apply silly-button bg-silly-accent text-white hover:shadow-lg hover:shadow-silly-accent/20 focus:ring-silly-accent/50": {},
        },
        ".silly-card": {
          "@apply bg-white rounded-3xl shadow-xl p-6 transition-all duration-300 hover:shadow-2xl": {},
        },
        ".heading-xl": {
          "@apply font-display text-4xl sm:text-5xl md:text-6xl font-bold tracking-tight": {},
        },
        ".heading-lg": {
          "@apply font-display text-3xl sm:text-4xl font-bold tracking-tight": {},
        },
        ".heading-md": {
          "@apply font-display text-2xl sm:text-3xl font-bold tracking-tight": {},
        },
        ".heading-sm": {
          "@apply font-display text-xl sm:text-2xl font-bold tracking-tight": {},
        },
        ".text-gradient": {
          "@apply bg-clip-text text-transparent bg-gradient-to-r": {},
        },
        ".animation-delay-2000": {
          "animation-delay": "2s",
        },
        ".animation-delay-4000": {
          "animation-delay": "4s",
        },
      });
    }),
    // Embed hero icons
    plugin(({ addVariant }) => {
      addVariant("phx-no-feedback", [".phx-no-feedback&", ".phx-no-feedback &"]);
      addVariant("phx-click-loading", [
        ".phx-click-loading&",
        ".phx-click-loading &",
      ]);
      addVariant("phx-submit-loading", [
        ".phx-submit-loading&",
        ".phx-submit-loading &",
      ]);
      addVariant("phx-change-loading", [
        ".phx-change-loading&",
        ".phx-change-loading &",
      ]);
    }),
    plugin(({ addBase }) => {
      addBase({
        ":root": {
          "--background": "0 0% 100%",
          "--foreground": "240 10% 3.9%",
          "--card": "0 0% 100%",
          "--card-foreground": "240 10% 3.9%",
          "--popover": "0 0% 100%",
          "--popover-foreground": "240 10% 3.9%",
          "--primary": "222.2 47.4% 11.2%",
          "--primary-foreground": "210 40% 98%",
          "--secondary": "210 40% 96.1%",
          "--secondary-foreground": "222.2 47.4% 11.2%",
          "--muted": "210 40% 96.1%",
          "--muted-foreground": "215.4 16.3% 46.9%",
          "--accent": "210 40% 96.1%",
          "--accent-foreground": "222.2 47.4% 11.2%",
          "--destructive": "0 84.2% 60.2%",
          "--destructive-foreground": "210 40% 98%",
          "--border": "214.3 31.8% 91.4%",
          "--input": "214.3 31.8% 91.4%",
          "--ring": "222.2 84% 4.9%",
          "--radius": "0.75rem",
          "--sidebar-background": "0 0% 98%",
          "--sidebar-foreground": "240 5.3% 26.1%",
          "--sidebar-primary": "240 5.9% 10%",
          "--sidebar-primary-foreground": "0 0% 98%",
          "--sidebar-accent": "240 4.8% 95.9%",
          "--sidebar-accent-foreground": "240 5.9% 10%",
          "--sidebar-border": "220 13% 91%",
          "--sidebar-ring": "217.2 91.2% 59.8%",
        },
        ".dark": {
          "--background": "222.2 84% 4.9%",
          "--foreground": "210 40% 98%",
          "--card": "222.2 84% 4.9%",
          "--card-foreground": "210 40% 98%",
          "--popover": "222.2 84% 4.9%",
          "--popover-foreground": "210 40% 98%",
          "--primary": "210 40% 98%",
          "--primary-foreground": "222.2 47.4% 11.2%",
          "--secondary": "217.2 32.6% 17.5%",
          "--secondary-foreground": "210 40% 98%",
          "--muted": "217.2 32.6% 17.5%",
          "--muted-foreground": "215 20.2% 65.1%",
          "--accent": "217.2 32.6% 17.5%",
          "--accent-foreground": "210 40% 98%",
          "--destructive": "0 62.8% 30.6%",
          "--destructive-foreground": "210 40% 98%",
          "--border": "217.2 32.6% 17.5%",
          "--input": "217.2 32.6% 17.5%",
          "--ring": "212.7 26.8% 83.9%",
          "--sidebar-background": "240 5.9% 10%",
          "--sidebar-foreground": "240 4.8% 95.9%",
          "--sidebar-primary": "224.3 76.3% 48%",
          "--sidebar-primary-foreground": "0 0% 100%",
          "--sidebar-accent": "240 3.7% 15.9%",
          "--sidebar-accent-foreground": "240 4.8% 95.9%",
          "--sidebar-border": "240 3.7% 15.9%",
          "--sidebar-ring": "217.2 91.2% 59.8%",
        },
      });
      addBase({
        "*": { "@apply border-border": {} },
        body: { "@apply bg-background text-foreground antialiased overflow-x-hidden": {} },
        html: { "@apply scroll-smooth": {} },
      });
    })
  ],
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        brand: "#FD4F00",
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        primary: {
          DEFAULT: "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
        },
        secondary: {
          DEFAULT: "hsl(var(--secondary))",
          foreground: "hsl(var(--secondary-foreground))",
        },
        destructive: {
          DEFAULT: "hsl(var(--destructive))",
          foreground: "hsl(var(--destructive-foreground))",
        },
        muted: {
          DEFAULT: "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        accent: {
          DEFAULT: "hsl(var(--accent))",
          foreground: "hsl(var(--accent-foreground))",
        },
        popover: {
          DEFAULT: "hsl(var(--popover))",
          foreground: "hsl(var(--popover-foreground))",
        },
        card: {
          DEFAULT: "hsl(var(--card))",
          foreground: "hsl(var(--card-foreground))",
        },
        sidebar: {
          DEFAULT: "hsl(var(--sidebar-background))",
          foreground: "hsl(var(--sidebar-foreground))",
          primary: "hsl(var(--sidebar-primary))",
          "primary-foreground": "hsl(var(--sidebar-primary-foreground))",
          accent: "hsl(var(--sidebar-accent))",
          "accent-foreground": "hsl(var(--sidebar-accent-foreground))",
          border: "hsl(var(--sidebar-border))",
          ring: "hsl(var(--sidebar-ring))",
        },
        // Custom colors for SillyConValley
        silly: {
          blue: "#0FA0CE",
          gray: "#404040",
          light: "#F8F8F8",
          accent: "#FF6B6B",
          success: "#4CAF50",
          purple: "#9b87f5",
          yellow: "#FFD166",
        },
        "silly-blue": "#4f46e5",  // indigo-600
        "silly-accent": "#f97316", // orange-500
        "silly-yellow": "#eab308", // yellow-500
        "silly-success": "#10b981", // emerald-500
        "silly-gray": "#475569",   // slate-600
        "silly-purple": "#7e22ce",  // purple-700
      },
      
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
      },
      
      keyframes: {
        "accordion-down": {
          from: { height: 0 },
          to: { height: "var(--radix-accordion-content-height)" },
        },
        "accordion-up": {
          from: { height: "var(--radix-accordion-content-height)" },
          to: { height: 0 },
        },
        "fade-in": {
          "0%": { opacity: "0", transform: "translateY(10px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
        "fade-in-right": {
          "0%": { opacity: "0", transform: "translateX(20px)" },
          "100%": { opacity: "1", transform: "translateX(0)" },
        },
        "float": {
          "0%, 100%": { transform: "translateY(0)" },
          "50%": { transform: "translateY(-10px)" },
        },
        "spin-slow": {
          "0%": { transform: "rotate(0deg)" },
          "100%": { transform: "rotate(360deg)" },
        },
        "bounce-subtle": {
          "0%, 100%": { transform: "translateY(0)" },
          "50%": { transform: "translateY(-5px)" },
        },
        "pulse-subtle": {
          "0%, 100%": { opacity: "1" },
          "50%": { opacity: "0.8" },
        },
        "blob": {
          "0%": { transform: "scale(1)" },
          "33%": { transform: "scale(1.1)" },
          "66%": { transform: "scale(0.9)" },
          "100%": { transform: "scale(1)" },
        },
        fadeIn: {
          '0%': { opacity: '0', transform: 'translateY(10px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        expandPanel: {
          '0%': { maxHeight: '0', opacity: '0' },
          '100%': { maxHeight: '50vh', opacity: '1' },
        },
      },
      
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
        "accordion-up": "accordion-up 0.2s ease-out",
        "fade-in": "fade-in 0.7s ease-out forwards",
        "fade-in-right": "fade-in-right 0.7s ease-out forwards",
        "float": "float 6s ease-in-out infinite",
        "spin-slow": "spin-slow 10s linear infinite",
        "bounce-subtle": "bounce-subtle 2s ease-in-out infinite",
        "pulse-subtle": "pulse-subtle 2s ease-in-out infinite",
        "blob": "blob 7s infinite",
        'fadeIn': 'fadeIn 0.2s ease-out',
        'expandPanel': 'expandPanel 0.3s ease',
      },
      
      fontFamily: {
        sans: [
          "Inter var, sans-serif",
          { fontFeatureSettings: '"cv02", "cv03", "cv04", "cv11"' },
        ],
        display: [
          "Cal Sans, Inter var, sans-serif",
          { fontFeatureSettings: '"cv02", "cv03", "cv04", "cv11"' },
        ],
      },
    },
  }
}
