rm -rf dist
mkdir -p dist

cp *html *webp *png *jpg *svg *css *md dist

if [ -f "$HOME/.cloudflare" ]; then
  source "$HOME/.cloudflare"
else
  die "Missing $HOME/.cloudflare with CLOUDFLARE_ACCOUNT_ID and CLOUDFLARE_API_TOKEN"
fi

docker run --rm -it \
  -v "$(pwd)":/workspace \
  -w /workspace \
  -e CLOUDFLARE_ACCOUNT_ID=${CLOUDFLARE_ACCOUNT_ID} \
  -e CLOUDFLARE_API_TOKEN=${CLOUDFLARE_API_TOKEN} \
  node:22 \
  npx --yes wrangler pages deploy dist --project-name=parallel-testing-2025 --branch=main