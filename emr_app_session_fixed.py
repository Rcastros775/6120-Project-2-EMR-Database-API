
import getpass
from typing import Any, Optional

import mysql.connector
from mysql.connector import Error

import warnings

warnings.filterwarnings("ignore", category=DeprecationWarning)


DB_HOST = "localhost"
DB_USER = "root"
DB_PASSWORD = "W3st42069!"  # replace with your local MySQL password
DB_NAME = "StudentClinicEMR_P2"


VALID_ROLES = {"Admin", "Doctor", "Nurse", "Receptionist", "Patient"}


def connect_to_db():
    """Create a MySQL connection."""
    try:
        return mysql.connector.connect(
            host=DB_HOST,
            user=DB_USER,
            password=DB_PASSWORD,
            database=DB_NAME,
        )
    except Error as exc:
        print(f"Database connection error: {exc}")
        return None


def none_if_blank(value: str) -> Optional[str]:
    value = value.strip()
    return value if value else None


def print_rows(cursor) -> bool:
    rows_printed = False

    for result in cursor.stored_results():
        rows = result.fetchall()

        if result.description:
            columns = [col[0] for col in result.description]
            print(" | ".join(columns))
            print("-" * 90)

        for row in rows:
            rows_printed = True
            if isinstance(row, dict):
                print(" | ".join(str(row.get(col, "")) for col in row.keys()))
            else:
                print(" | ".join(str(value) for value in row))

    return rows_printed


def call_proc(conn, proc_name: str, args: Optional[list[Any]] = None, fetch: bool = True):
    """Call a stored procedure safely and commit/rollback as needed."""
    args = args or []
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.callproc(proc_name, args)

        if fetch:
            rows_printed = print_rows(cursor)
            if not rows_printed:
                print("Done.")
        else:
            for result in cursor.stored_results():
                result.fetchall()
            print("Done.")

        conn.commit()
    except Error as exc:
        conn.rollback()
        print(f"Error: {exc.msg}")
    finally:
        cursor.close()


def set_session_context(conn, user: dict[str, Any]):
    """Set MySQL session variables used by stored procedures/triggers for RBAC and audit trails."""
    cursor = conn.cursor()
    try:
        cursor.execute("SET @current_app_user = %s", (user.get("Username"),))
        cursor.execute("SET @current_app_role = %s", (user.get("UserRole"),))
        cursor.execute("SET @current_app_user_id = %s", (user.get("UserID"),))
        cursor.execute("SET @current_staff_id = %s", (user.get("StaffID"),))
        cursor.execute("SET @current_patient_id = %s", (user.get("PatientID"),))
        conn.commit()
    finally:
        cursor.close()


def login():
    """Authenticate user through the login stored procedure."""
    conn = connect_to_db()
    if not conn:
        return None, None

    print("\n" + "=" * 30)
    print("LOGIN")
    print("=" * 30)

    username = input("Username: ").strip()
    password = getpass.getpass("Password: ")

    cursor = conn.cursor(dictionary=True)
    try:
        cursor.callproc("sp_Admin_Login", [username, password])

        user = None
        for result in cursor.stored_results():
            user = result.fetchone()
            break

        if not user:
            print("Invalid username or password.")
            conn.close()
            return None, None

        if user.get("UserRole") not in VALID_ROLES:
            print(f"Invalid role returned from database: {user.get('UserRole')}")
            conn.close()
            return None, None

        set_session_context(conn, user)
        print(f"Logged in as {user['Username']} ({user['UserRole']}).")
        return user, conn

    except Error as exc:
        print(f"Login error: {exc.msg}")
        conn.close()
        return None, None
    finally:
        cursor.close()


def admin_menu(conn):
    while True:
        print("\n--- ADMIN PORTAL ---")
        print("1. View security feed")
        print("2. Add user")
        print("3. Enable/disable user")
        print("4. Exit")
        choice = input("Choice: ").strip()

        if choice == "1":
            call_proc(conn, "sp_Admin_GetSecurityFeed")

        elif choice == "2":
            staff_id = none_if_blank(input("Staff ID (blank if patient user): "))
            patient_id = none_if_blank(input("Patient ID (blank if staff user): "))
            username = input("New username: ").strip()
            password = getpass.getpass("New password: ")
            role = input("Role (Admin/Doctor/Nurse/Receptionist/Patient): ").strip()
            call_proc(conn, "sp_Admin_AddUser", [staff_id, patient_id, username, password, role], fetch=False)

        elif choice == "3":
            user_id = input("User ID: ").strip()
            is_active = input("Active? 1=yes, 0=no: ").strip()
            call_proc(conn, "sp_Admin_ToggleUser", [user_id, is_active], fetch=False)

        elif choice == "4":
            break
        else:
            print("Invalid choice.")


def doctor_menu(conn):
    while True:
        print("\n--- DOCTOR PORTAL ---")
        print("1. View patient dashboard")
        print("2. Add diagnosis")
        print("3. Add prescription")
        print("4. Exit")
        choice = input("Choice: ").strip()

        if choice == "1":
            patient_id = input("Patient ID: ").strip()
            call_proc(conn, "sp_Doc_GetPatientDashboard", [patient_id])

        elif choice == "2":
            visit_id = input("Visit ID: ").strip()
            code = input("Diagnosis code: ").strip()
            notes = input("Notes: ").strip()
            call_proc(conn, "sp_Doc_AddDiagnosis", [visit_id, code, notes], fetch=False)

        elif choice == "3":
            visit_id = input("Visit ID: ").strip()
            medication = input("Medication name: ").strip()
            dosage = input("Dosage: ").strip()
            instructions = input("Instructions: ").strip()
            call_proc(conn, "sp_Doc_AddPrescription", [visit_id, medication, dosage, instructions], fetch=False)

        elif choice == "4":
            break
        else:
            print("Invalid choice.")


def nurse_menu(conn):
    while True:
        print("\n--- NURSE PORTAL ---")
        print("1. View triage queue")
        print("2. Add symptom")
        print("3. Record lab result")
        print("4. Exit")
        choice = input("Choice: ").strip()

        if choice == "1":
            call_proc(conn, "sp_Nurse_GetTriageQueue")

        elif choice == "2":
            visit_id = input("Visit ID: ").strip()
            symptom_id = input("Symptom ID: ").strip()
            severity = input("Severity (Mild/Moderate/Severe): ").strip()
            call_proc(conn, "sp_Nurse_AddSymptom", [visit_id, symptom_id, severity], fetch=False)

        elif choice == "3":
            visit_id = input("Visit ID: ").strip()
            test_name = input("Test name: ").strip()
            result_value = input("Result value: ").strip()
            call_proc(conn, "sp_Nurse_UpdateLab", [visit_id, test_name, result_value], fetch=False)

        elif choice == "4":
            break
        else:
            print("Invalid choice.")


def receptionist_menu(conn):
    while True:
        print("\n--- RECEPTIONIST PORTAL ---")
        print("1. Register patient")
        print("2. Search patient")
        print("3. Book appointment")
        print("4. Process payment")
        print("5. Update patient contact info")
        print("6. Exit")
        choice = input("Choice: ").strip()

        if choice == "1":
            first = input("First name: ").strip()
            last = input("Last name: ").strip()
            dob = input("DOB (YYYY-MM-DD): ").strip()
            gender = input("Gender (Male/Female/Other): ").strip()
            phone = input("Phone: ").strip()
            email = input("Email: ").strip()
            call_proc(conn, "sp_Recept_RegisterPatient", [first, last, dob, gender, phone, email])

        elif choice == "2":
            last = input("Last name starts with: ").strip()
            call_proc(conn, "sp_Recept_SearchPatient", [last])

        elif choice == "3":
            patient_id = input("Patient ID: ").strip()
            staff_id = input("Doctor Staff ID: ").strip()
            facility_id = input("Facility ID: ").strip()
            visit_date = input("Visit date/time (YYYY-MM-DD HH:MM:SS): ").strip()
            reason = input("Reason for visit: ").strip()
            call_proc(conn, "sp_Recept_BookAppt", [patient_id, staff_id, facility_id, visit_date, reason])

        elif choice == "4":
            visit_id = input("Visit ID: ").strip()
            amount = input("Payment amount: ").strip()
            call_proc(conn, "sp_Recept_ProcessPayment", [visit_id, amount], fetch=False)

        elif choice == "5":
            patient_id = input("Patient ID: ").strip()
            phone = input("New phone: ").strip()
            email = input("New email: ").strip()
            call_proc(conn, "sp_Patient_UpdateContact", [patient_id, phone, email], fetch=False)

        elif choice == "6":
            break
        else:
            print("Invalid choice.")


def patient_menu(conn, user):
    while True:
        print("\n--- PATIENT PORTAL ---")
        print("1. View my history")
        print("2. Update my contact info")
        print("3. Exit")
        choice = input("Choice: ").strip()

        if choice == "1":
            call_proc(conn, "sp_Patient_GetMyHistory", [user["Username"]])

        elif choice == "2":
            patient_id = user.get("PatientID")
            if patient_id is None:
                print("This user account is not linked to a patient record.")
                continue
            phone = input("New phone: ").strip()
            email = input("New email: ").strip()
            call_proc(conn, "sp_Patient_UpdateContact", [patient_id, phone, email], fetch=False)

        elif choice == "3":
            break
        else:
            print("Invalid choice.")


def main_menu(user, conn):
    set_session_context(conn, user)

    role = user["UserRole"]
    if role == "Admin":
        admin_menu(conn)
    elif role == "Doctor":
        doctor_menu(conn)
    elif role == "Nurse":
        nurse_menu(conn)
    elif role == "Receptionist":
        receptionist_menu(conn)
    elif role == "Patient":
        patient_menu(conn, user)
    else:
        print(f"Unknown role: {role}")


if __name__ == "__main__":
    current_user, connection = login()
    if current_user and connection:
        try:
            main_menu(current_user, connection)
        finally:
            connection.close()
            print("Goodbye.")
