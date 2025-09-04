module.exports = function (sequelize, DataTypes) {
  const Guardado = sequelize.define('guardado', {
    id: {
      autoIncrement: true,
      type: DataTypes.INTEGER,
      allowNull: false,
      primaryKey: true
    },
    idutilizador: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    idpost: {
      type: DataTypes.INTEGER,
      allowNull: false
    }
  }, {
    tableName: 'guardados',
    schema: 'public',
    timestamps: false
  });

  // Definir associações
  Guardado.associate = function(models) {
    // Um guardado pertence a um post
    Guardado.belongsTo(models.post, {
      foreignKey: 'idpost',
      as: 'post'
    });
    
    // Um guardado pertence a um utilizador
    Guardado.belongsTo(models.utilizador, {
      foreignKey: 'idutilizador',
      as: 'utilizador'
    });
  };

  return Guardado;
};