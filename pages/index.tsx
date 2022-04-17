import type { NextPage } from 'next'
import Head from 'next/head'
import Image from 'next/image'
import styles from '../styles/Home.module.css'

const Home: NextPage = () => {
	return (
		<div className={styles.container}>
			<Head>
				<title>Lajebo</title>
				<link rel='icon' href='/favicon.ico' />
			</Head>

			<main className={styles.main}>
				<h1 className={styles.title}>Lajebo Games</h1>

				<div className={styles.grid}>
					<div>
						<a href='https://www.roblox.com/games/7107498084'>
							<h2>Anime Battle Simulator &rarr;</h2>
						</a>
					</div>
				</div>
			</main>
		</div>
	)
}

export default Home
