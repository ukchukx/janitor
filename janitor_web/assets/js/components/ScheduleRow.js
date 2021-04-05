import React, { Component } from 'react';
import PropTypes from 'prop-types';

class ScheduleBackupRow extends Component {
  static propTypes = {
    schedule: PropTypes.object.isRequired,
    index: PropTypes.number.isRequired,
    view: PropTypes.func.isRequired,
    selectForUpdate: PropTypes.func.isRequired,
    deleteSchedule: PropTypes.func.isRequired,
    deletingSchedule: PropTypes.number.isRequired
  };

  render() {
    const { 
      schedule: { frequency, name, days, times, db, preserve, host },
      index,
      deletingSchedule
    } = this.props;
    const deleteClasses = (i) => 
      `button is-outlined is-danger ${i === deletingSchedule ? 'is-loading' : ''}`;

    return (
      <tr>
        <td>{name}</td>
        <td>
          <span className="tag">{db}</span>
        </td>
        <td>{host}</td>
        <td>{frequency === 'weekly' ? `${days} @ ${times}` : `Daily @ ${times}`}</td>
        <td>{preserve} backups</td>
        <td>
          <div className="buttons are-small">
            <button
              onClick={(_) => this.props.view(index)}
              className="button is-outlined">
              View
            </button>
            <button
              onClick={(_) => this.props.selectForUpdate(index)}
              className="button is-outlined">
              Update
            </button>
            <button
              onClick={(_) => this.props.deleteSchedule(index)}
              className={deleteClasses(index)}>
              Delete
            </button>
          </div>
        </td>
      </tr>
    );
  }
}

export default ScheduleBackupRow;