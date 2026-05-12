package org.example.project.data.room

import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.sqlite.driver.bundled.BundledSQLiteDriver
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import platform.Foundation.NSDocumentDirectory
import platform.Foundation.NSFileManager
import platform.Foundation.NSURL
import platform.Foundation.NSUserDomainMask

@Suppress("EXPECT_ACTUAL_CLASSIFIERS_ARE_IN_BETA_WARNING")
actual object AppDatabaseConstructor : RoomDatabaseConstructor<AppDatabase> {
    private var instance: AppDatabase? = null

    override fun initialize(): AppDatabase {
        return instance ?: throw IllegalStateException("Call IosAppDatabase.create() first")
    }

    fun create(): AppDatabase {
        if (instance == null) {
            instance = Room.databaseBuilder(
                name = documentDirectory().path + "/factory.db",
                factory = { AppDatabase::class.instantiateImpl() }
            )
                .setDriver(BundledSQLiteDriver())
                .setQueryCoroutineContext(Dispatchers.IO)
                .fallbackToDestructiveMigration(dropAllTables = true)
                .build()
        }
        return instance!!
    }

    private fun documentDirectory(): NSURL {
        return NSFileManager.defaultManager.URLForDirectory(
            directory = NSDocumentDirectory,
            inDomain = NSUserDomainMask,
            appropriateForURL = null,
            create = true,
            error = null
        )!!
    }
}