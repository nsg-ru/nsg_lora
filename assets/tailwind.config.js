const colors = require('tailwindcss/colors')

module.exports = {
  purge: [
    "../**/*.html.eex",
    "../**/*.html.leex",
    "../**/views/**/*.ex",
    "../**/live/**/*.ex",
    "./js/**/*.js"
  ],
  darkMode: 'class',
  theme: {
    container: {},
    colors: {
      transparent: 'transparent',
      current: 'currentColor',
      gray: colors.blueGray,
      blue: colors.lightBlue,
      red: colors.red,
    }
  },
  variants: {
    extend: {},
  },
  plugins: [],
}
