# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-only TFM such as `net472` or `net48`, update it accordingly.

---

## 2. Restore and Build the Solution

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate compatibility issues, particularly around deprecated APIs or platform-specific code paths.

---

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

---

## 4. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any remaining Windows-specific API calls (e.g., `System.Windows.Forms`, `Microsoft.Win32`, COM interop). These will not function on Linux or macOS without additional handling.

You can also run the API compatibility analyzer via:

```bash
dotnet add package Microsoft.DotNet.ApiCompat
```

---

## 5. Validate ADO-Specific Functionality

Since the project is named `AdoCore`, it likely involves data access. Verify the following:

- **Connection strings** are correctly configured for the target environment.
- **Database drivers** (e.g., `System.Data.SqlClient` vs `Microsoft.Data.SqlClient`) are updated. It is recommended to migrate from `System.Data.SqlClient` to `Microsoft.Data.SqlClient` for cross-platform support:

```bash
dotnet add package Microsoft.Data.SqlClient
```

- Any `DataAdapter`, `DataSet`, or `DataTable` usage still compiles and behaves as expected, as these are supported but may have subtle differences.

---

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to catch any runtime issues that do not surface during compilation:

```bash
dotnet run --configuration Release
```

---

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
# For Linux x64
dotnet publish -c Release -r linux-x64 --self-contained false

# For Windows x64
dotnet publish -c Release -r win-x64 --self-contained false
```

Use `--self-contained true` if you want to bundle the .NET runtime with the output.

---

## 8. Review Output Artifacts

Check the `publish` output directory to confirm all required assemblies, configuration files, and dependencies are present before deploying to the target environment.