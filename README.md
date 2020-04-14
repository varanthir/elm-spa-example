# elm-spa-example

My proposition of Elm SPA example with refresh and access JWT tokens for authentication.  
For development purposses access token has 10 seconds of expiration, refresh token has 10 minutes of expiration.  
My intention was to focus on app logic so I keep very simple UI.

It was inspired by Richard Feldman's [elm-spa-example](https://github.com/rtfeldman/elm-spa-example)

## Requirements

- `node` (tested on ver. 10.17.0)
- `yarn` (tested on ver. 1.22.4)

## Scripts

- `yarn` - install dependencies
- `yarn start` - start development server at http://localhost:8000
- `yarn api` - start BE server at http://localhost:3000
- `yarn test` - run BE tests
- `yarn build` - production build with artifacts in `/build`
- `yarn server` - serve built app at http://localhost:8080
