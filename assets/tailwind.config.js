module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/flashy/**/*.*ex"
  ],
  theme: {
    extend: {},
  },
  plugins: [
    require("@tailwindcss/forms")
  ]
}
