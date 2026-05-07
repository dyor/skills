package org.example.project.domain

import androidx.room.Room
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test

actual fun getInMemoryDatabase(): AppDatabase {
    val databaseBuilder = Room.inMemoryDatabaseBuilder<AppDatabase>()
    return getRoomDatabase(databaseBuilder)
}

class IosScriptDaoTest : ScriptDaoTest() {
    private lateinit var database: AppDatabase
    private lateinit var scriptDao: ScriptDao

    @BeforeTest
    fun setup() {
        database = getInMemoryDatabase()
        scriptDao = database.scriptDao()
    }

    @AfterTest
    fun teardown() {
        database.close()
    }

    @Test
    override fun testScriptInsertAndRetrieve() = runTest {
        super.testScriptInsertAndRetrieve()
    }
}