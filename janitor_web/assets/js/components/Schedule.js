import React, { Component } from 'react';
import PropTypes from 'prop-types';
import ScheduleBackups from './ScheduleBackups';
import { makeRequest } from '../utils';

class Schedule extends Component {
  static propTypes = {
    schedule: PropTypes.object.isRequired,
    endpoint: PropTypes.string.isRequired,
    updateSchedule: PropTypes.func.isRequired,
  };

  state = {
    busy: false,
    deletingBackup: -1
  };

  deleteBackup(index) {
    if (! confirm('Are you sure?')) return;

    let { props: { endpoint, schedule: { id, backups } } } = this;
    this.setState({ deletingBackup: index });

    makeRequest(`${endpoint}${id}/backups/${backups[index].name}/delete`, 'delete')
    .then(response => response.status === 200 ? response.json() : null)
    .then((schedule) => {
      this.props.updateSchedule(schedule);
    })
    .finally(() => this.setState({ deletingBackup: -1 }));
  }

  backupNow() {
    if (this.state.busy) return;

    this.setState({ busy: true });

    const { props: { endpoint, schedule } } = this;

    makeRequest(`${endpoint}${schedule.id}/backups/create`, 'post')
      .then(response => response.status === 200 ? response.json() : null)
      .then((schedule) => {
        if (schedule) {
          this.props.updateSchedule(schedule);
        } else {
          alert('Could not create backup');
        }
      })
      .finally(() => this.setState({ busy: false }));
  }

  render() {
    const { 
      props: { schedule: { backups, days, times, name, db, host, port, frequency } },
      state: { busy, deletingBackup }
    } = this;
    const backupButtonClasses = `button is-fullwidth is-primary is-outlined${busy ? ' is-loading' : ''}`;

    return (
      <div className="column">
        <h2 className="subtitle">
          <strong>{name}</strong>
        </h2>
        <h4>{db}://{host}:{port}/{name}</h4>
        <span className="tag is-dark">
          {frequency === 'weekly' ? `${days} @ ${times}` : `Daily @ ${times}`}
        </span>
        <hr/>
        <button onClick={_ => this.backupNow()} disabled={busy} className={backupButtonClasses}>
          Backup now
        </button>
        <ScheduleBackups
          backups={backups}
          deletingBackup={deletingBackup}
          deleteBackup={this.deleteBackup.bind(this)}
        />
        
      </div>
    );
  }
}

export default Schedule;