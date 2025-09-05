module.exports = function (sequelize, DataTypes) {
  const Guardado = sequelize.define('guardado', {
    id: {
      autoIncrement: true,
      type: DataTypes.INTEGER,
      allowNull: false,
      primaryKey: true
    },
    id_utilizador: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    id_curso: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    data_guardado: {
      type: DataTypes.DATE,
      allowNull: true
    }
  }, {
    tableName: 'guardados',
    schema: 'public',
    timestamps: false
  });

  // Definir associações
  Guardado.associate = function(models) {
    // Um guardado pertence a um curso
    Guardado.belongsTo(models.cursos, {
      foreignKey: 'id_curso',
      as: 'curso'
    });
    
    // Um guardado pertence a um utilizador
    Guardado.belongsTo(models.utilizador, {
      foreignKey: 'id_utilizador',
      as: 'utilizador'
    });
  };

  return Guardado;
};