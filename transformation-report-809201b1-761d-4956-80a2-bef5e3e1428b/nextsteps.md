# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy the project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that may indicate compatibility concerns, even if they do not prevent compilation.

## 3. Review Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0`). Ensure no projects are still referencing `net48` or other Windows-only frameworks unless intentionally required.

## 4. Check for Windows-Specific APIs

Even without build errors, the code may use APIs that are Windows-only. Run the .NET compatibility analyzer to surface any such usages:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay attention to warnings prefixed with `CA1416` (platform compatibility). These indicate calls that may fail on non-Windows operating systems.

## 5. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences introduced by the framework migration rather than pre-existing bugs.

## 6. Verify Runtime Behavior Manually

Run the application and exercise its primary workflows manually. Pay particular attention to:

- File I/O paths, as path separator differences (`\` vs `/`) can cause issues on Linux and macOS.
- Configuration file loading (e.g., `app.config` vs `appsettings.json`).
- Any reflection-based code, which may behave differently under newer .NET runtimes.

## 7. Audit Removed APIs

Some APIs available in .NET Framework are not present in cross-platform .NET. Review the [.NET Upgrade Assistant compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) for any breaking changes relevant to the frameworks involved in this migration.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target platform:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed. Review the publish output directory to confirm all required assets are present.