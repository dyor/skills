package org.example.project.di

import androidx.room.RoomDatabase
import org.example.project.data.GeminiService
import org.example.project.data.GeminiServiceImpl
import org.example.project.domain.AppDatabase
import org.example.project.domain.getRoomDatabase
import org.example.project.domain.ScriptDao

object AppContainer {
    private var _database: AppDatabase? = null
    val database: AppDatabase
        get() = _database ?: throw IllegalStateException("Database not initialized")

    val scriptDao: ScriptDao
        get() = database.scriptDao()

    val geminiService: GeminiService by lazy { GeminiServiceImpl() }

    fun init(builder: RoomDatabase.Builder<AppDatabase>) {
        if (_database == null) {
            _database = getRoomDatabase(builder)
        }
    }
}