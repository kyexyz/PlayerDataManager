/** @type {import('next').NextConfig} */
const nextConfig = {
	reactStrictMode: true,
	images: {
		domains: ['media.discordapp.net'],
	},
	async redirects() {
		return [
			{
				source: '/abs',
				destination: 'https://www.roblox.com/games/7107498084',
				permanent: false,
			},
			{
				source: '/',
				destination:
					'https://www.roblox.com/groups/9634774/Lajebo-Games#!/about',
				permanent: false,
			},
		]
	},
}

module.exports = nextConfig
