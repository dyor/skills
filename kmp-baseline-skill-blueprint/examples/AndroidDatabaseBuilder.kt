package org.example.project.data.room

import android.content.Context
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.sqlite.driver.bundled.BundledSQLiteDriver
import kotlinx.coroutines.Dispatchers
import org.example.project.data.room.AppDatabase
import org.example.project.data.room.AppDatabaseConstructor

@Suppress("EXPECT_ACTUAL_CLASSIFIERS_ARE_IN_BETA_WARNING")
actual object AppDatabaseConstructor : RoomDatabaseConstructor<AppDatabase> {
    private var instance: AppDatabase? = null

    override fun initialize(): AppDatabase {
        return instance ?: throw IllegalStateException("Call AndroidAppDatabase.create(context) first")
    }

    fun create(context: Context): AppDatabase {
        if (instance == null) {
            instance = Room.databaseBuilder(
                context = context.applicationContext,
                name = context.getDatabasePath("factory.db").absolutePath
            )
                .setDriver(BundledSQLiteDriver())
                .setQueryCoroutineContext(Dispatchers.IO)
                .fallbackToDestructiveMigration(dropAllTables = true)
                .build()
        }
        return instance!!
    }
}