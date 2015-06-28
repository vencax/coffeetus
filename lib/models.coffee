

module.exports = (sequelize, DataTypes) ->

  sequelize.define 'upload',
    id:
      type: DataTypes.STRING
      allowNull: false
      primaryKey: true
    final_length:
      type: DataTypes.INTEGER
      defaultValue: 0  # in seconds
    state:
      type: DataTypes.INTEGER
      allowNull: false
      defaultValue: 0
    created_on:
      type: DataTypes.INTEGER
      allowNull: false
      defaultValue: Date.now()
    offset:
      type: DataTypes.INTEGER
      allowNull: false
      defaultValue: 0
    received:
      type: DataTypes.INTEGER
      allowNull: false
      defaultValue: 0
  ,
    timestamps: false
