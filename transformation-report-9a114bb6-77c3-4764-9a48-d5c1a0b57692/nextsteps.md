# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). For example:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if they do not produce build errors.

## 3. Review NuGet Package Versions

Check all `<PackageReference>` entries in `AdoCore.csproj` and any other projects in the solution. Ensure packages are targeting versions compatible with your chosen .NET target framework. You can use the following command to check for outdated packages:

```bash
dotnet list package --outdated
```

Update packages where appropriate, then rebuild to confirm nothing breaks.

## 4. Run Existing Tests

If the solution contains test projects, execute the test suite to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework APIs and their cross-platform .NET equivalents.

## 5. Check for Platform-Specific API Usage

Even without build errors, some APIs that compiled successfully may behave differently or throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Pay particular attention to:

- `System.Data` and ADO.NET provider usage (relevant given the `AdoCore` project name)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions
- COM interop or P/Invoke calls

Run the application on each target platform (Windows, Linux, macOS) if cross-platform support is a goal.

## 6. Test Database Connectivity

Since this project appears to be ADO.NET related, verify that all database connection strings, providers, and drivers function correctly under the new runtime. Confirm that the appropriate NuGet driver package is referenced (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) and that connections can be established in a test environment.

## 7. Validate Application Output

Run the application end-to-end in a staging or test environment and compare the output and behavior against the legacy version to confirm functional equivalence.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory and deploy to your target environment according to your standard deployment process.