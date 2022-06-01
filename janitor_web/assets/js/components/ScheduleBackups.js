import React, { Component } from 'react';
import PropTypes from 'prop-types';
import { downloadBackupFile } from '../utils';

class ScheduleBackups extends Component {
  static propTypes = {
    backups: PropTypes.array.isRequired,
    deleteBackup: PropTypes.func.isRequired,
    deletingBackup: PropTypes.number.isRequired
  };

  state = {
    downloading: -1
  };

  downloadFile(index) {
    const { download_link, name } = this.props.backups[index];

    this.setState({ downloading: index });

    if (!download_link) {
      alert('No auth header.');
      return;
    }

    downloadBackupFile(download_link, name)
      .finally(() => this.setState({ downloading: -1 }));
  }

  render() {
    const styles = { marginTop: '30px' };
    const { props: { backups, deletingBackup }, state: { downloading } } = this;
    const downloadClasses = (index) => 
      `button is-outlined ${downloading === index ? 'is-loading' : ''}`;
    const deleteClasses = (index) => 
      `button is-outlined is-danger ${deletingBackup === index ? 'is-loading' : ''}`;

    return (
      <div className="backups" style={styles}>
        {!backups.length ?
          <p>No backups available</p> :
          (
            <table className="table is-striped">
              <thead>
                <tr>
                  <th>File</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
              {backups.map((b, i) => (
                  <tr key={i}>
                    <td>{b.name}</td>
                    <td>
                      <div className="buttons are-small">
                        <a onClick={(_) => this.downloadFile(i)} className={downloadClasses(i)}>
                          Download
                        </a>
                        <button
                          onClick={(_) => this.props.deleteBackup(i)}
                          className={deleteClasses(i)}>
                          Delete
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )
        }
      </div>
    );
  }
}

export default ScheduleBackups;