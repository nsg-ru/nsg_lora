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
      gray: colors.coolGray,
      blue: colors.lightBlue,
      red: colors.red,
    },
        minHeight: {
       '0': '0',
       'cell': '2rem'
      }
  },
  variants: {
    extend: {},
  },
  plugins: [],
}
